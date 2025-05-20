defmodule AshRdf.Sparql.DataLayer do
  @moduledoc """
  Ash data layer for SPARQL endpoints.
  
  This data layer integrates with SPARQL endpoints, allowing Ash resources
  to be stored and queried using SPARQL. It handles the translation of Ash
  operations to SPARQL and converts results back to Ash resources.
  """

  use Ash.DataLayer

  alias Ash.Actions.Sort
  alias Ash.Filter
  alias Ash.Query
  alias AshRdf.Sparql.Client
  alias AshRdf.Sparql.HttpClient
  alias AshRdf.Sparql.QueryBuilder
  alias AshRdf.Sparql.ResponseParser

  @impl true
  def can?(resource, :create), do: true
  def can?(resource, :read), do: true
  def can?(resource, :update), do: true
  def can?(resource, :destroy), do: true
  
  # Relationship handling - depends on capability
  def can?(resource, :join_relationship), do: true
  def can?(resource, :runtime_join_relationship), do: true
  
  # Transactions - depends on SPARQL endpoint capabilities
  def can?(resource, :transaction), do: false
  def can?(resource, :nested_transaction), do: false
  
  # Aggregates - basic ones supported via SPARQL
  def can?(resource, :aggregate), do: true
  def can?(resource, {:aggregate, :count}), do: true
  def can?(resource, {:aggregate, :sum}), do: true
  def can?(resource, {:aggregate, :avg}), do: true
  def can?(resource, {:aggregate, :min}), do: true
  def can?(resource, {:aggregate, :max}), do: true
  def can?(resource, {:aggregate, _}), do: false

  @impl true
  def resource_to_query(resource) do
    Ash.Query.new(resource)
  end

  @impl true
  def run_query(query, options) do
    resource = Query.resource(query)
    
    # Get endpoint configuration
    endpoint = get_endpoint(resource, options)
    client_options = get_client_options(resource, options)
    
    # Build SPARQL query
    sparql_query = QueryBuilder.build_select(query)
    
    # Execute query
    with {:ok, client} <- HttpClient.init(endpoint, client_options),
         {:ok, results} <- HttpClient.select(client, sparql_query),
         {:ok, records} <- ResponseParser.parse_select_results(results, resource) do
      {:ok, records}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def create(changeset, options) do
    resource = Ash.Changeset.resource(changeset)
    
    # Get endpoint configuration
    endpoint = get_endpoint(resource, options)
    client_options = get_client_options(resource, options)
    
    # Build SPARQL INSERT query
    sparql_query = QueryBuilder.build_insert(changeset)
    
    # Execute query
    with {:ok, client} <- HttpClient.init(endpoint, client_options),
         {:ok, _} <- HttpClient.update(client, sparql_query) do
      # Return the new record
      attributes = Ash.Changeset.attributes(changeset)
      {:ok, struct(resource, attributes)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def update(changeset, options) do
    resource = Ash.Changeset.resource(changeset)
    
    # Get endpoint configuration
    endpoint = get_endpoint(resource, options)
    client_options = get_client_options(resource, options)
    
    # Build SPARQL UPDATE query
    sparql_query = QueryBuilder.build_update(changeset)
    
    # Execute query
    with {:ok, client} <- HttpClient.init(endpoint, client_options),
         {:ok, _} <- HttpClient.update(client, sparql_query) do
      # Return the updated record
      attributes = Ash.Changeset.attributes(changeset)
      record = struct(resource, attributes)
      {:ok, record}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def destroy(resource, record, options) do
    # Get endpoint configuration
    endpoint = get_endpoint(resource, options)
    client_options = get_client_options(resource, options)
    
    # Build SPARQL DELETE query
    sparql_query = QueryBuilder.build_delete(record)
    
    # Execute query
    with {:ok, client} <- HttpClient.init(endpoint, client_options),
         {:ok, _} <- HttpClient.update(client, sparql_query) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def transaction(_resource, function, _options) do
    # Basic implementation - no transaction support
    # Some SPARQL endpoints do support transactions, but this would need 
    # endpoint-specific implementation
    {:error, :not_supported}
  end

  @impl true
  def get_by(resource, filters, options) do
    # Convert filters to an Ash query and run it
    query = 
      resource
      |> Ash.Query.new()
      |> Ash.Query.filter(filters)
      |> Ash.Query.limit(1)
    
    case run_query(query, options) do
      {:ok, [record]} -> {:ok, record}
      {:ok, []} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def offset_limit(query, offset, limit) do
    # Apply offset and limit to the query
    query
    |> Query.limit(limit)
    |> Query.offset(offset)
  end

  @impl true
  def sort(query, sort) do
    # Apply sorting to the query
    Query.sort(query, sort)
  end

  @impl true
  def filter(query, filter) do
    # Apply filter to the query
    Query.filter(query, filter)
  end

  @impl true
  def source(resource) do
    # Return the source configuration for the resource
    # For SPARQL, this is the endpoint URL and other configuration
    AshRdf.Dsl.Info.sparql_source(resource) || %{}
  end

  # Helper functions

  defp get_endpoint(resource, options) do
    # Get endpoint from options or resource configuration
    Keyword.get(options, :endpoint) || 
      get_in(source(resource), [:endpoint]) ||
      raise "No SPARQL endpoint specified for resource #{inspect(resource)}"
  end

  defp get_client_options(resource, options) do
    # Merge options from resource configuration and provided options
    resource_options = get_in(source(resource), [:client_options]) || []
    
    # Add credentials if present
    credentials = 
      cond do
        Keyword.has_key?(options, :credentials) ->
          Keyword.get(options, :credentials)
          
        has_in?(source(resource), [:credentials]) ->
          get_in(source(resource), [:credentials])
          
        true ->
          nil
      end
    
    # Build final options
    client_options = Keyword.merge(resource_options, Keyword.drop(options, [:endpoint, :credentials]))
    
    if credentials do
      Keyword.put(client_options, :credentials, credentials)
    else
      client_options
    end
  end

  defp has_in?(map, keys) when is_map(map) do
    Enum.reduce_while(keys, map, fn key, acc ->
      if is_map(acc) && Map.has_key?(acc, key) do
        {:cont, Map.get(acc, key)}
      else
        {:halt, false}
      end
    end) != false
  end
  
  defp has_in?(_, _), do: false
end