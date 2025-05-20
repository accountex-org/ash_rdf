defmodule AshRdf.Sparql.ConnectionPool do
  @moduledoc """
  A connection pool manager for SPARQL endpoints.
  
  Handles connection pooling and lifecycle management for both HTTP and WebSocket 
  connections to SPARQL endpoints, with features like:
  - Dynamic pool sizing based on demand
  - Automatic reconnection
  - Connection health checking
  - Connection lifecycle management
  """
  
  use GenServer
  
  alias AshRdf.Sparql.Client
  
  # Default options
  @default_pool_size 10
  @default_max_overflow 5
  @default_checkout_timeout 5000
  @default_idle_interval 1000 * 60 * 5  # 5 minutes
  
  # Client API
  
  @doc """
  Start a new connection pool for a SPARQL endpoint.
  """
  def start_link(opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)
    name = Keyword.get(opts, :name, pool_name_from_endpoint(endpoint))
    
    GenServer.start_link(__MODULE__, opts, name: name)
  end
  
  @doc """
  Check out a connection from the pool.
  """
  def checkout(pool, timeout \\ 5000) do
    GenServer.call(pool, :checkout, timeout)
  end
  
  @doc """
  Return a connection to the pool.
  """
  def checkin(pool, conn) do
    GenServer.cast(pool, {:checkin, conn})
  end
  
  @doc """
  Execute a function with a connection and automatically return it to the pool.
  """
  def with_conn(pool, fun, timeout \\ 5000) do
    case checkout(pool, timeout) do
      {:ok, conn} ->
        try do
          fun.(conn)
        after
          checkin(pool, conn)
        end
        
      error ->
        error
    end
  end
  
  # Server callbacks
  
  @impl true
  def init(opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)
    client_module = Keyword.get(opts, :client_module, AshRdf.Sparql.HttpClient)
    pool_size = Keyword.get(opts, :pool_size, @default_pool_size)
    max_overflow = Keyword.get(opts, :max_overflow, @default_max_overflow)
    idle_interval = Keyword.get(opts, :idle_interval, @default_idle_interval)
    client_opts = Keyword.get(opts, :client_options, [])
    
    # Create the initial pool
    {:ok, pool} = create_initial_pool(endpoint, client_module, pool_size, client_opts)
    
    # Start the idle connection checker
    if idle_interval > 0 do
      Process.send_after(self(), :check_idle_connections, idle_interval)
    end
    
    {:ok, %{
      endpoint: endpoint,
      client_module: client_module,
      pool_size: pool_size,
      max_overflow: max_overflow,
      client_options: client_opts,
      idle_interval: idle_interval,
      available: pool,
      in_use: %{},
      waiting: :queue.new(),
      overflow: 0
    }}
  end
  
  @impl true
  def handle_call(:checkout, from, %{available: available} = state) do
    case Map.keys(available) do
      [] ->
        # No available connections
        handle_empty_pool(from, state)
        
      [conn_id | _] ->
        # Get the first available connection
        conn = Map.get(available, conn_id)
        new_available = Map.delete(available, conn_id)
        new_in_use = Map.put(state.in_use, conn_id, {conn, from})
        
        {:reply, {:ok, conn}, %{state | available: new_available, in_use: new_in_use}}
    end
  end
  
  @impl true
  def handle_cast({:checkin, conn}, state) do
    # Find the connection in the in_use map
    case Enum.find(state.in_use, fn {_, {c, _}} -> c == conn end) do
      {conn_id, _} ->
        # Return it to the available pool
        new_in_use = Map.delete(state.in_use, conn_id)
        new_available = Map.put(state.available, conn_id, conn)
        
        # Check if anyone is waiting for a connection
        case :queue.out(state.waiting) do
          {{:value, {from, _timer_ref}}, new_waiting} ->
            # Immediately check out the connection for the waiting process
            GenServer.reply(from, {:ok, conn})
            {:noreply, %{state | in_use: new_in_use, waiting: new_waiting}}
            
          {:empty, _} ->
            # No one waiting, just return the connection to the pool
            {:noreply, %{state | in_use: new_in_use, available: new_available}}
        end
        
      nil ->
        # Connection not found in in_use, might be a duplicate checkin
        {:noreply, state}
    end
  end
  
  @impl true
  def handle_info({:connection_timeout, from}, state) do
    # Find the waiting request
    case find_waiting_request(state.waiting, from) do
      {waiting_item, new_waiting} ->
        {_, timer_ref} = waiting_item
        # Cancel the timer if it's still active
        if timer_ref, do: Process.cancel_timer(timer_ref)
        
        # Reply with timeout error
        GenServer.reply(from, {:error, :checkout_timeout})
        
        # Update state
        {:noreply, %{state | waiting: new_waiting}}
        
      nil ->
        # Request not found in waiting queue, ignore
        {:noreply, state}
    end
  end
  
  @impl true
  def handle_info(:check_idle_connections, state) do
    # Ping each available connection to check health
    {new_available, to_reconnect} = Enum.reduce(state.available, {%{}, []}, fn {conn_id, conn}, {acc_avail, acc_reconnect} ->
      case Client.ping(conn) do
        :ok ->
          # Connection is healthy
          {Map.put(acc_avail, conn_id, conn), acc_reconnect}
          
        {:error, _} ->
          # Connection is unhealthy, mark for reconnection
          {acc_avail, [conn_id | acc_reconnect]}
      end
    end)
    
    # Reconnect unhealthy connections
    new_state = Enum.reduce(to_reconnect, %{state | available: new_available}, fn conn_id, acc_state ->
      case connect(acc_state.endpoint, acc_state.client_module, acc_state.client_options) do
        {:ok, new_conn} ->
          # Successfully reconnected
          %{acc_state | available: Map.put(acc_state.available, conn_id, new_conn)}
          
        {:error, _} ->
          # Failed to reconnect
          acc_state
      end
    end)
    
    # Schedule next check
    if state.idle_interval > 0 do
      Process.send_after(self(), :check_idle_connections, state.idle_interval)
    end
    
    {:noreply, new_state}
  end
  
  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # A connection process died
    # Find it in both available and in_use pools
    case find_connection_by_pid(state.available, pid) do
      {conn_id, _conn} ->
        # Remove from available and try to reconnect
        new_available = Map.delete(state.available, conn_id)
        
        case connect(state.endpoint, state.client_module, state.client_options) do
          {:ok, new_conn} ->
            # Successfully reconnected
            {:noreply, %{state | available: Map.put(new_available, conn_id, new_conn)}}
            
          {:error, _} ->
            # Failed to reconnect
            {:noreply, %{state | available: new_available}}
        end
        
      nil ->
        # Check in_use pool
        case find_connection_by_pid(state.in_use, pid) do
          {conn_id, {_conn, from}} ->
            # Remove from in_use
            new_in_use = Map.delete(state.in_use, conn_id)
            
            # Reply with error to the process using this connection
            GenServer.reply(from, {:error, :connection_lost})
            
            # Try to reconnect
            case connect(state.endpoint, state.client_module, state.client_options) do
              {:ok, new_conn} ->
                # Successfully reconnected
                new_available = Map.put(state.available, conn_id, new_conn)
                {:noreply, %{state | in_use: new_in_use, available: new_available}}
                
              {:error, _} ->
                # Failed to reconnect
                {:noreply, %{state | in_use: new_in_use}}
            end
            
          nil ->
            # Not found in either pool, ignore
            {:noreply, state}
        end
    end
  end
  
  # Private helper functions
  
  defp handle_empty_pool(from, state) do
    cond do
      state.overflow < state.max_overflow ->
        # Create a new overflow connection
        case connect(state.endpoint, state.client_module, state.client_options) do
          {:ok, conn} ->
            # Use a timestamp as the connection ID
            conn_id = "conn_#{System.system_time(:millisecond)}"
            new_in_use = Map.put(state.in_use, conn_id, {conn, from})
            
            # Monitor the connection process
            if is_pid(conn), do: Process.monitor(conn)
            
            {:reply, {:ok, conn}, %{state | in_use: new_in_use, overflow: state.overflow + 1}}
            
          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
        
      true ->
        # Queue the request
        timer_ref = Process.send_after(
          self(),
          {:connection_timeout, from},
          @default_checkout_timeout
        )
        
        new_waiting = :queue.in({from, timer_ref}, state.waiting)
        {:noreply, %{state | waiting: new_waiting}}
    end
  end
  
  defp create_initial_pool(endpoint, client_module, pool_size, client_opts) do
    # Create the initial pool of connections
    result = Enum.reduce_while(1..pool_size, %{}, fn i, acc ->
      case connect(endpoint, client_module, client_opts) do
        {:ok, conn} ->
          conn_id = "conn_#{i}"
          
          # Monitor the connection process
          if is_pid(conn), do: Process.monitor(conn)
          
          {:cont, Map.put(acc, conn_id, conn)}
          
        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    
    case result do
      %{} = pool -> {:ok, pool}
      error -> error
    end
  end
  
  defp connect(endpoint, client_module, client_opts) do
    client_module.connect(endpoint, client_opts)
  end
  
  defp pool_name_from_endpoint(endpoint) do
    uri = URI.parse(endpoint)
    name = "#{uri.host}_#{uri.port || 80}"
    String.to_atom("sparql_pool_#{name}")
  end
  
  defp find_waiting_request(waiting, from) do
    case :queue.out(waiting) do
      {{:value, {^from, _timer_ref} = item}, new_waiting} ->
        {item, new_waiting}
        
      {{:value, other_item}, new_waiting} ->
        case find_waiting_request(new_waiting, from) do
          {found_item, newest_waiting} ->
            {found_item, :queue.in(other_item, newest_waiting)}
            
          nil ->
            nil
        end
        
      {:empty, _} ->
        nil
    end
  end
  
  defp find_connection_by_pid(conn_map, pid) do
    Enum.find(conn_map, fn
      {_id, %{conn: ^pid}} -> true
      {_id, ^pid} -> true
      {_id, {^pid, _}} -> true
      _ -> false
    end)
  end
end