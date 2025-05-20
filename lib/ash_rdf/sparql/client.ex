defmodule AshRdf.Sparql.Client do
  @moduledoc """
  Behaviour defining the interface for SPARQL clients.
  
  This module provides a standardized interface for different SPARQL client
  implementations (HTTP, WebSocket, etc.), ensuring consistent connection
  management and query execution.
  """

  @type endpoint :: String.t()
  @type credentials :: %{
    optional(:username) => String.t(),
    optional(:password) => String.t(),
    optional(:token) => String.t(),
    optional(:auth_method) => :basic | :bearer | :custom
  }
  @type query :: String.t()
  @type query_type :: :select | :construct | :ask | :describe | :update
  @type result_format :: :json | :xml | :csv | :tsv | :turtle | :ntriples | :jsonld
  @type headers :: [{String.t(), String.t()}]
  @type options :: keyword()
  @type response :: {:ok, term()} | {:error, term()}

  @doc """
  Initialize a new client instance with the given configuration.
  """
  @callback init(endpoint, options) :: {:ok, term()} | {:error, term()}

  @doc """
  Execute a SPARQL query against the configured endpoint.
  """
  @callback query(term(), query, query_type, result_format, options) :: response

  @doc """
  Execute a SPARQL SELECT query and return results.
  """
  @callback select(term(), query, result_format, options) :: response

  @doc """
  Execute a SPARQL CONSTRUCT query and return an RDF graph.
  """
  @callback construct(term(), query, result_format, options) :: response

  @doc """
  Execute a SPARQL ASK query and return a boolean result.
  """
  @callback ask(term(), query, options) :: {:ok, boolean()} | {:error, term()}

  @doc """
  Execute a SPARQL DESCRIBE query and return an RDF graph.
  """
  @callback describe(term(), query, result_format, options) :: response

  @doc """
  Execute a SPARQL UPDATE query to modify data.
  """
  @callback update(term(), query, options) :: {:ok, :updated} | {:error, term()}

  @doc """
  Close the connection and release resources.
  """
  @callback close(term()) :: :ok | {:error, term()}

  @doc """
  Set authentication credentials for the client instance.
  """
  @callback authenticate(term(), credentials) :: {:ok, term()} | {:error, term()}

  @doc """
  Check if the client is connected to the endpoint.
  """
  @callback connected?(term()) :: boolean()

  @doc """
  Get information about the SPARQL endpoint capabilities.
  """
  @callback capabilities(term()) :: {:ok, map()} | {:error, term()}

  @optional_callbacks [
    capabilities: 1,
    authenticate: 2,
    close: 1,
    connected?: 1
  ]
end