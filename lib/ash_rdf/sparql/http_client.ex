defmodule AshRdf.Sparql.HttpClient do
  @moduledoc """
  HTTP-based implementation of the SPARQL client.
  
  This module implements the `AshRdf.Sparql.Client` behaviour using HTTP
  requests to communicate with SPARQL endpoints according to the SPARQL
  Protocol specification.
  """

  @behaviour AshRdf.Sparql.Client

  @default_headers [{"Accept", "application/sparql-results+json"}]
  @default_timeout 30_000

  defmodule State do
    @moduledoc false
    defstruct [
      :endpoint,
      :tesla_client,
      :credentials,
      :middleware,
      :options
    ]
  end

  @impl true
  def init(endpoint, options \\ []) do
    middleware = [
      {Tesla.Middleware.BaseUrl, endpoint},
      {Tesla.Middleware.Headers, @default_headers},
      {Tesla.Middleware.Timeout, timeout: Keyword.get(options, :timeout, @default_timeout)},
      Tesla.Middleware.JSON
    ]

    # Add optional middleware based on options
    middleware = 
      if Keyword.get(options, :follow_redirects, true) do
        middleware ++ [{Tesla.Middleware.FollowRedirects, max_redirects: 3}]
      else
        middleware
      end

    # Apply auth middleware if credentials provided
    middleware = 
      case Keyword.get(options, :credentials) do
        nil -> middleware
        credentials -> add_auth_middleware(middleware, credentials)
      end

    state = %State{
      endpoint: endpoint,
      middleware: middleware,
      tesla_client: Tesla.client(middleware),
      credentials: Keyword.get(options, :credentials),
      options: options
    }

    {:ok, state}
  end

  @impl true
  def query(state, query, query_type, result_format, options \\ []) do
    case query_type do
      :select -> select(state, query, result_format, options)
      :construct -> construct(state, query, result_format, options)
      :ask -> ask(state, query, options)
      :describe -> describe(state, query, result_format, options)
      :update -> update(state, query, options)
      _ -> {:error, {:unsupported_query_type, query_type}}
    end
  end

  @impl true
  def select(state, query, result_format \\ :json, options \\ []) do
    headers = format_accept_header(result_format)
    params = [{"query", query}] ++ query_params(options)

    case Tesla.get(state.tesla_client, "/sparql", query: params, headers: headers) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}
      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}
      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  @impl true
  def construct(state, query, result_format \\ :turtle, options \\ []) do
    headers = format_accept_header(result_format)
    params = [{"query", query}] ++ query_params(options)

    case Tesla.get(state.tesla_client, "/sparql", query: params, headers: headers) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}
      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}
      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  @impl true
  def ask(state, query, options \\ []) do
    params = [{"query", query}] ++ query_params(options)
    headers = [{"Accept", "application/sparql-results+json"}]

    case Tesla.get(state.tesla_client, "/sparql", query: params, headers: headers) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        # Extract boolean result from SPARQL JSON response
        case body do
          %{"boolean" => result} when is_boolean(result) -> {:ok, result}
          _ -> {:error, {:invalid_response, :missing_boolean_result}}
        end
      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}
      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  @impl true
  def describe(state, query, result_format \\ :turtle, options \\ []) do
    # DESCRIBE returns RDF data, similar to CONSTRUCT
    construct(state, query, result_format, options)
  end

  @impl true
  def update(state, query, options \\ []) do
    # SPARQL 1.1 Update operations are typically sent as POST
    headers = [{"Content-Type", "application/sparql-update"}]
    params = query_params(options)

    case Tesla.post(state.tesla_client, "/sparql", query, query: params, headers: headers) do
      {:ok, %{status: status}} when status in 200..299 ->
        {:ok, :updated}
      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}
      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  @impl true
  def close(_state) do
    # HTTP client doesn't maintain persistent connections that need explicit closing
    :ok
  end

  @impl true
  def authenticate(state, credentials) do
    new_middleware = 
      state.middleware
      |> Enum.reject(fn 
        {Tesla.Middleware.BasicAuth, _} -> true
        {Tesla.Middleware.BearerAuth, _} -> true
        _ -> false
      end)
      |> add_auth_middleware(credentials)

    new_state = %{
      state |
      middleware: new_middleware,
      tesla_client: Tesla.client(new_middleware),
      credentials: credentials
    }

    {:ok, new_state}
  end

  @impl true
  def connected?(state) do
    # Simple connection check by sending a minimal query
    case ask(state, "ASK { ?s ?p ?o } LIMIT 1") do
      {:ok, _} -> true
      _ -> false
    end
  end

  @impl true
  def capabilities(state) do
    # Try to extract capabilities from service description
    # This is a common convention but not universally implemented
    query = """
    SELECT ?feature WHERE {
      ?endpoint a sd:Service ;
                sd:feature ?feature .
    }
    """

    case select(state, query) do
      {:ok, results} ->
        # Extract features from results and convert to map
        features = 
          results
          |> extract_bindings()
          |> Enum.map(fn %{"feature" => %{"value" => feature}} -> feature end)
          |> Enum.into(MapSet.new())

        {:ok, %{
          features: features,
          supports_update: MapSet.member?(features, "http://www.w3.org/ns/sparql-service-description#UpdateViaPOST"),
          supports_service_description: true
        }}
      
      {:error, _} ->
        # Fallback: check if endpoint supports basic operations
        supports_update = 
          case update(state, "INSERT DATA { <http://example.org/test> <http://example.org/test> \"test\" }") do
            {:ok, _} -> true
            _ -> false
          end

        {:ok, %{
          features: MapSet.new(),
          supports_update: supports_update,
          supports_service_description: false
        }}
    end
  end

  # Private helpers

  defp add_auth_middleware(middleware, credentials) do
    case credentials do
      %{auth_method: :basic, username: username, password: password} ->
        middleware ++ [{Tesla.Middleware.BasicAuth, %{username: username, password: password}}]
      
      %{auth_method: :bearer, token: token} ->
        middleware ++ [{Tesla.Middleware.BearerAuth, %{token: token}}]
      
      %{auth_method: :custom} ->
        # Custom auth would need to be implemented by the user
        middleware
      
      _ ->
        middleware
    end
  end

  defp format_accept_header(format) do
    mime_type = case format do
      :json -> "application/sparql-results+json"
      :xml -> "application/sparql-results+xml"
      :csv -> "text/csv"
      :tsv -> "text/tab-separated-values"
      :turtle -> "text/turtle"
      :ntriples -> "application/n-triples"
      :jsonld -> "application/ld+json"
      _ -> "application/sparql-results+json"  # Default
    end

    [{"Accept", mime_type}]
  end

  defp query_params(options) do
    params = []

    params = 
      if timeout = Keyword.get(options, :timeout) do
        params ++ [{"timeout", to_string(timeout)}]
      else
        params
      end

    params =
      if default_graph = Keyword.get(options, :default_graph) do
        params ++ [{"default-graph-uri", default_graph}]
      else
        params
      end

    params =
      if named_graphs = Keyword.get(options, :named_graphs) do
        Enum.reduce(named_graphs, params, fn graph, acc ->
          acc ++ [{"named-graph-uri", graph}]
        end)
      else
        params
      end

    params
  end

  defp extract_bindings(%{"results" => %{"bindings" => bindings}}) do
    bindings
  end
  defp extract_bindings(_), do: []
end