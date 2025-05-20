defmodule AshRdf.Sparql.WebsocketClient do
  @moduledoc """
  WebSocket-based SPARQL client implementation.
  
  Uses Gun (via Mint.WebSocket) for persistent WebSocket connections to SPARQL endpoints.
  This client is particularly useful for streaming results and maintaining 
  long-lived connections.
  """
  
  @behaviour AshRdf.Sparql.Client
  
  alias AshRdf.Sparql.ResponseParser
  
  @default_timeout 30_000
  
  # Connection record to keep track of the WebSocket state
  defmodule Connection do
    @moduledoc false
    defstruct [
      :endpoint,
      :conn,
      :ws_stream,
      :auth,
      :options,
      :request_counter,
      :requests,
      :ref
    ]
  end
  
  # Request record for tracking in-flight requests
  defmodule Request do
    @moduledoc false
    defstruct [
      :id,
      :from,
      :type,
      :query,
      :params,
      :timeout_ref,
      :buffer
    ]
  end

  @impl true
  def connect(endpoint, options \\ []) do
    uri = URI.parse(endpoint)
    host = to_charlist(uri.host)
    port = uri.port || (if uri.scheme == "wss", do: 443, else: 80)
    ws_path = uri.path || "/"
    
    # Configure SSL if using secure WebSocket
    transport = if uri.scheme == "wss", do: :ssl, else: :tcp
    transport_opts = if transport == :ssl, do: [verify: :verify_peer], else: []
    
    # Connect using Gun (via Mint.WebSocket)
    with {:ok, conn} <- :gun.open(host, port, %{transport: transport, transport_opts: transport_opts}),
         {:ok, _protocol} <- :gun.await_up(conn),
         # Upgrade the connection to WebSocket
         stream_ref = :gun.ws_upgrade(conn, ws_path),
         {:ok, ws_stream} <- await_ws_upgrade(conn, stream_ref) do
      
      # Create and monitor the connection
      connection = %Connection{
        endpoint: endpoint,
        conn: conn,
        ws_stream: ws_stream,
        auth: nil,
        options: options,
        request_counter: 0,
        requests: %{},
        ref: stream_ref
      }
      
      # Start a process to handle WebSocket messages
      {:ok, pid} = AshRdf.Sparql.WebsocketHandler.start_link(connection)
      
      {:ok, pid}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def disconnect(connection) do
    GenServer.call(connection, :disconnect)
  end

  @impl true
  def query(connection, query, options \\ []) do
    timeout = Keyword.get(options, :timeout, @default_timeout)
    GenServer.call(connection, {:query, query, options}, timeout)
  end

  @impl true
  def update(connection, update, options \\ []) do
    timeout = Keyword.get(options, :timeout, @default_timeout)
    GenServer.call(connection, {:update, update, options}, timeout)
  end

  @impl true
  def authenticate(connection, auth_credentials) do
    GenServer.call(connection, {:authenticate, auth_credentials})
  end

  @impl true
  def ping(connection) do
    GenServer.call(connection, :ping)
  end

  @impl true
  def query_with_parameters(connection, query, params, options \\ []) do
    timeout = Keyword.get(options, :timeout, @default_timeout)
    GenServer.call(connection, {:query_with_parameters, query, params, options}, timeout)
  end
  
  # Private helper functions
  
  defp await_ws_upgrade(conn, ref) do
    receive do
      {:gun_upgrade, ^conn, ^ref, ["websocket"], _headers} ->
        {:ok, %{conn: conn, ref: ref}}
      
      {:gun_response, ^conn, ^ref, _, status, headers} ->
        {:error, %{status: status, headers: headers}}
      
      {:gun_error, ^conn, ^ref, reason} ->
        {:error, reason}
      
      other ->
        {:error, {:unexpected_message, other}}
    after
      5000 ->
        {:error, :timeout}
    end
  end
end

defmodule AshRdf.Sparql.WebsocketHandler do
  @moduledoc """
  GenServer implementation for handling WebSocket connection and messages.
  """
  
  use GenServer
  
  alias AshRdf.Sparql.WebsocketClient.{Connection, Request}
  alias AshRdf.Sparql.ResponseParser
  
  # Client API
  
  def start_link(connection) do
    GenServer.start_link(__MODULE__, connection)
  end
  
  # Server callbacks
  
  @impl true
  def init(connection) do
    # Monitor the Gun connection process
    Process.monitor(connection.conn)
    {:ok, connection}
  end
  
  @impl true
  def handle_call(:disconnect, _from, state) do
    :gun.close(state.conn)
    {:reply, :ok, state}
  end
  
  @impl true
  def handle_call({:query, query, options}, from, state) do
    request_id = state.request_counter + 1
    
    # Create a unique message ID for this request
    msg_id = "#{request_id}"
    
    # Create a timeout reference
    timeout = Keyword.get(options, :timeout, 30_000)
    timeout_ref = Process.send_after(self(), {:request_timeout, msg_id}, timeout)
    
    # Store the request information
    request = %Request{
      id: msg_id,
      from: from,
      type: :query,
      query: query,
      timeout_ref: timeout_ref,
      buffer: ""
    }
    
    # Send the query message over the WebSocket
    message = Jason.encode!(%{
      id: msg_id,
      type: "query",
      query: query
    })
    
    :gun.ws_send(state.conn, state.ref, {:text, message})
    
    # Update state with the new request
    new_state = %{state | 
      request_counter: request_id,
      requests: Map.put(state.requests, msg_id, request)
    }
    
    {:noreply, new_state}
  end
  
  @impl true
  def handle_call({:update, update, options}, from, state) do
    request_id = state.request_counter + 1
    
    # Create a unique message ID for this request
    msg_id = "#{request_id}"
    
    # Create a timeout reference
    timeout = Keyword.get(options, :timeout, 30_000)
    timeout_ref = Process.send_after(self(), {:request_timeout, msg_id}, timeout)
    
    # Store the request information
    request = %Request{
      id: msg_id,
      from: from,
      type: :update,
      query: update,
      timeout_ref: timeout_ref,
      buffer: ""
    }
    
    # Send the update message over the WebSocket
    message = Jason.encode!(%{
      id: msg_id,
      type: "update",
      update: update
    })
    
    :gun.ws_send(state.conn, state.ref, {:text, message})
    
    # Update state with the new request
    new_state = %{state | 
      request_counter: request_id,
      requests: Map.put(state.requests, msg_id, request)
    }
    
    {:noreply, new_state}
  end
  
  @impl true
  def handle_call({:authenticate, auth_credentials}, _from, state) do
    {auth_method, credentials} = auth_credentials
    
    # Create authentication message based on method
    auth_message = case auth_method do
      :basic ->
        username = Keyword.fetch!(credentials, :username)
        password = Keyword.fetch!(credentials, :password)
        
        Jason.encode!(%{
          type: "auth",
          method: "basic",
          username: username,
          password: password
        })
        
      :bearer ->
        token = Keyword.fetch!(credentials, :token)
        
        Jason.encode!(%{
          type: "auth",
          method: "bearer",
          token: token
        })
        
      :none ->
        nil
    end
    
    if auth_message do
      :gun.ws_send(state.conn, state.ref, {:text, auth_message})
      {:reply, {:ok, self()}, %{state | auth: auth_credentials}}
    else
      {:reply, {:ok, self()}, %{state | auth: nil}}
    end
  end
  
  @impl true
  def handle_call(:ping, from, state) do
    request_id = state.request_counter + 1
    msg_id = "#{request_id}"
    
    # Create a timeout reference
    timeout_ref = Process.send_after(self(), {:request_timeout, msg_id}, 5000)
    
    # Store the request information
    request = %Request{
      id: msg_id,
      from: from,
      type: :ping,
      timeout_ref: timeout_ref
    }
    
    # Send a ping message
    message = Jason.encode!(%{
      id: msg_id,
      type: "ping"
    })
    
    :gun.ws_send(state.conn, state.ref, {:text, message})
    
    # Update state with the new request
    new_state = %{state | 
      request_counter: request_id,
      requests: Map.put(state.requests, msg_id, request)
    }
    
    {:noreply, new_state}
  end
  
  @impl true
  def handle_call({:query_with_parameters, query, params, options}, from, state) do
    # Replace parameter placeholders with actual values similar to HttpClient
    processed_query = Enum.reduce(params, query, fn {key, value}, acc ->
      placeholder = "?#{key}"
      replacement = format_parameter_value(value)
      String.replace(acc, placeholder, replacement)
    end)
    
    # Delegate to regular query
    handle_call({:query, processed_query, options}, from, state)
  end
  
  # WebSocket message handling
  
  @impl true
  def handle_info({:gun_ws, _pid, _ref, {:text, msg}}, state) do
    case Jason.decode(msg) do
      {:ok, response} ->
        handle_ws_response(response, state)
      
      {:error, _} ->
        # Invalid JSON response, just log and continue
        {:noreply, state}
    end
  end
  
  @impl true
  def handle_info({:gun_ws, _pid, _ref, {:close, code, reason}}, state) do
    # WebSocket closed by server
    # Respond to all pending requests with an error
    Enum.each(state.requests, fn {_id, request} ->
      GenServer.reply(request.from, {:error, {:ws_closed, code, reason}})
      if request.timeout_ref, do: Process.cancel_timer(request.timeout_ref)
    end)
    
    # Terminate the process
    {:stop, {:ws_closed, code, reason}, state}
  end
  
  @impl true
  def handle_info({:DOWN, _ref, :process, pid, reason}, %{conn: pid} = state) do
    # Gun process died, terminate
    {:stop, {:gun_down, reason}, state}
  end
  
  @impl true
  def handle_info({:request_timeout, req_id}, state) do
    case Map.get(state.requests, req_id) do
      nil ->
        # Request already completed, ignore
        {:noreply, state}
        
      request ->
        # Timeout occurred, reply with error
        GenServer.reply(request.from, {:error, :timeout})
        
        # Remove the request from state
        new_state = %{state | requests: Map.delete(state.requests, req_id)}
        {:noreply, new_state}
    end
  end
  
  # Private helper functions
  
  defp handle_ws_response(%{"id" => id} = response, state) do
    case Map.get(state.requests, id) do
      nil ->
        # No matching request found, ignore
        {:noreply, state}
        
      request ->
        # Cancel timeout timer
        if request.timeout_ref, do: Process.cancel_timer(request.timeout_ref)
        
        result = case response do
          %{"type" => "response", "status" => "success", "data" => data} ->
            parse_response_data(data, request)
            
          %{"type" => "error", "message" => message} ->
            {:error, message}
            
          %{"type" => "pong"} ->
            :ok
            
          _ ->
            {:error, :invalid_response}
        end
        
        # Reply to the caller
        GenServer.reply(request.from, result)
        
        # Remove the request from state
        new_state = %{state | requests: Map.delete(state.requests, id)}
        {:noreply, new_state}
    end
  end
  
  defp handle_ws_response(_response, state) do
    # Response without an ID, ignore
    {:noreply, state}
  end
  
  defp parse_response_data(data, %{type: :query, query: query}) do
    cond do
      String.starts_with?(String.upcase(query), "ASK") ->
        {:ok, Map.get(data, "boolean", false)}
        
      String.starts_with?(String.upcase(query), "SELECT") ->
        {:ok, Map.get(data, "results", %{})}
        
      String.starts_with?(String.upcase(query), "CONSTRUCT") or 
      String.starts_with?(String.upcase(query), "DESCRIBE") ->
        {:ok, Map.get(data, "graph", [])}
        
      true ->
        {:error, :unsupported_query_type}
    end
  end
  
  defp parse_response_data(_data, %{type: :update}) do
    {:ok, :success}
  end
  
  defp format_parameter_value(value) when is_binary(value) do
    # Escape quotes and wrap in quotes
    "\"#{String.replace(value, "\"", "\\\"")}\""
  end
  
  defp format_parameter_value(value) when is_integer(value) or is_float(value) do
    to_string(value)
  end
  
  defp format_parameter_value(true), do: "true"
  defp format_parameter_value(false), do: "false"
  
  defp format_parameter_value(%URI{} = uri) do
    "<#{URI.to_string(uri)}>"
  end
  
  defp format_parameter_value(value) do
    raise ArgumentError, "Unsupported parameter value: #{inspect(value)}"
  end
end