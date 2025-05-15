defmodule AshRdf.Rdf.Graph do
  @moduledoc """
  Represents an RDF graph, which is a collection of RDF statements.
  """
  
  alias AshRdf.Rdf.Statement
  
  defstruct [
    :name,
    statements: [],
    namespaces: %{}
  ]
  
  @type t :: %__MODULE__{
    name: String.t() | nil,
    statements: [Statement.t()],
    namespaces: map()
  }
  
  @doc """
  Creates a new empty RDF graph.
  """
  def new(opts \\ []) do
    name = Keyword.get(opts, :name)
    namespaces = Keyword.get(opts, :namespaces, %{})
    
    %__MODULE__{
      name: name,
      statements: [],
      namespaces: Map.merge(default_namespaces(), namespaces)
    }
  end
  
  @doc """
  Adds a statement to the graph.
  """
  def add(%__MODULE__{} = graph, %Statement{} = statement) do
    %__MODULE__{graph | statements: [statement | graph.statements]}
  end
  
  @doc """
  Adds a statement to the graph using subject, predicate, and object.
  """
  def add(%__MODULE__{} = graph, subject, predicate, object, opts \\ []) do
    statement = Statement.new(subject, predicate, object, opts)
    add(graph, statement)
  end
  
  @doc """
  Removes a statement from the graph.
  """
  def remove(%__MODULE__{} = graph, %Statement{} = statement) do
    %__MODULE__{graph | statements: Enum.reject(graph.statements, &equal_statements?(&1, statement))}
  end
  
  defp equal_statements?(s1, s2) do
    s1.subject == s2.subject && s1.predicate == s2.predicate && s1.object == s2.object
  end
  
  @doc """
  Adds a namespace prefix to the graph.
  """
  def add_namespace(%__MODULE__{} = graph, prefix, uri) do
    %__MODULE__{graph | namespaces: Map.put(graph.namespaces, prefix, uri)}
  end
  
  @doc """
  Finds statements matching a pattern.
  """
  def find(%__MODULE__{} = graph, subject \\ nil, predicate \\ nil, object \\ nil) do
    Enum.filter(graph.statements, fn statement ->
      (subject == nil || statement.subject == subject) &&
      (predicate == nil || statement.predicate == predicate) &&
      (object == nil || statement.object == object)
    end)
  end
  
  @doc """
  Finds a single statement matching a pattern.
  """
  def find_one(%__MODULE__{} = graph, subject \\ nil, predicate \\ nil, object \\ nil) do
    Enum.find(graph.statements, fn statement ->
      (subject == nil || statement.subject == subject) &&
      (predicate == nil || statement.predicate == predicate) &&
      (object == nil || statement.object == object)
    end)
  end
  
  @doc """
  Merges two graphs together.
  """
  def merge(%__MODULE__{} = graph1, %__MODULE__{} = graph2) do
    %__MODULE__{
      name: graph1.name,
      statements: graph1.statements ++ graph2.statements,
      namespaces: Map.merge(graph1.namespaces, graph2.namespaces)
    }
  end
  
  @doc """
  Resolves all URIs in the graph against a base URI.
  """
  def resolve_uris(%__MODULE__{} = graph, base_uri) do
    resolved_statements = Enum.map(graph.statements, &Statement.resolve_uris(&1, base_uri))
    %__MODULE__{graph | statements: resolved_statements}
  end
  
  @doc """
  Serializes the graph to Turtle format.
  """
  def to_turtle(%__MODULE__{} = graph) do
    AshRdf.Rdf.Serializer.to_turtle(graph.statements, graph.namespaces)
  end
  
  @doc """
  Serializes the graph to N-Triples format.
  """
  def to_ntriples(%__MODULE__{} = graph) do
    AshRdf.Rdf.Serializer.to_ntriples(graph.statements)
  end
  
  @doc """
  Serializes the graph to JSON-LD format.
  """
  def to_jsonld(%__MODULE__{} = graph) do
    context = Enum.map(graph.namespaces, fn {prefix, uri} -> {prefix, uri} end) |> Map.new()
    AshRdf.Rdf.Serializer.to_jsonld(graph.statements, context)
  end
  
  @doc """
  Creates a graph from Turtle data.
  """
  def from_turtle(turtle_string, opts \\ []) do
    statements = AshRdf.Rdf.Parser.parse_turtle(turtle_string)
    
    graph = new(opts)
    %__MODULE__{graph | statements: statements}
  end
  
  @doc """
  Creates a graph from N-Triples data.
  """
  def from_ntriples(ntriples_string, opts \\ []) do
    statements = AshRdf.Rdf.Parser.parse_ntriples(ntriples_string)
    
    graph = new(opts)
    %__MODULE__{graph | statements: statements}
  end
  
  defp default_namespaces do
    %{
      "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
      "owl" => "http://www.w3.org/2002/07/owl#",
      "xsd" => "http://www.w3.org/2001/XMLSchema#"
    }
  end
end