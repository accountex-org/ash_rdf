defmodule AshRdf.Rdf do
  @moduledoc """
  Main module for RDF functionality in AshRdf.
  """
  
  alias AshRdf.Rdf.{Graph, Statement, Resource, Uri}
  
  @doc """
  Creates a new empty RDF graph.
  """
  def new_graph(opts \\ []) do
    Graph.new(opts)
  end
  
  @doc """
  Creates a new RDF statement (triple).
  """
  def statement(subject, predicate, object, opts \\ []) do
    Statement.new(subject, predicate, object, opts)
  end
  
  @doc """
  Converts an Ash resource instance to RDF statements.
  """
  def resource_to_rdf(resource_module, resource_instance) do
    Resource.to_rdf(resource_module, resource_instance)
  end
  
  @doc """
  Creates an Ash resource instance from RDF statements.
  """
  def resource_from_rdf(resource_module, statements) do
    Resource.from_rdf(resource_module, statements)
  end
  
  @doc """
  Gets the RDF representation of an Ash resource as a graph.
  """
  def resource_to_graph(resource_module, resource_instance, opts \\ []) do
    statements = resource_to_rdf(resource_module, resource_instance)
    
    namespaces = Resource.namespaces(resource_module)
    
    graph = Graph.new(Keyword.put_new(opts, :namespaces, namespaces))
    
    Enum.reduce(statements, graph, fn statement, acc ->
      Graph.add(acc, statement)
    end)
  end
  
  @doc """
  Serializes an Ash resource to Turtle format.
  """
  def resource_to_turtle(resource_module, resource_instance) do
    resource_module
    |> resource_to_graph(resource_instance)
    |> Graph.to_turtle()
  end
  
  @doc """
  Serializes an Ash resource to N-Triples format.
  """
  def resource_to_ntriples(resource_module, resource_instance) do
    resource_module
    |> resource_to_graph(resource_instance)
    |> Graph.to_ntriples()
  end
  
  @doc """
  Serializes an Ash resource to JSON-LD format.
  """
  def resource_to_jsonld(resource_module, resource_instance) do
    resource_module
    |> resource_to_graph(resource_instance)
    |> Graph.to_jsonld()
  end
  
  @doc """
  Loads RDF data from a Turtle string.
  """
  def load_turtle(turtle_string, opts \\ []) do
    Graph.from_turtle(turtle_string, opts)
  end
  
  @doc """
  Loads RDF data from an N-Triples string.
  """
  def load_ntriples(ntriples_string, opts \\ []) do
    Graph.from_ntriples(ntriples_string, opts)
  end
  
  @doc """
  Resolves a URI against a base URI.
  """
  def resolve_uri(uri, base_uri) do
    Uri.resolve(uri, base_uri)
  end
  
  @doc """
  Gets the local name (fragment or last path segment) from a URI.
  """
  def local_name(uri) do
    Uri.local_name(uri)
  end
end