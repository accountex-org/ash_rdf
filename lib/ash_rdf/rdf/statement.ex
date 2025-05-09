defmodule AshRdf.Rdf.Statement do
  @moduledoc """
  Represents an RDF statement (triple) consisting of subject, predicate, and object.
  """
  
  alias AshRdf.Rdf.Uri
  
  defstruct [
    :subject,
    :predicate,
    :object,
    :datatype,
    :language,
    graph: nil
  ]
  
  @type literal_value :: String.t() | number() | boolean() | Date.t() | DateTime.t() | NaiveDateTime.t()
  
  @type t :: %__MODULE__{
    subject: String.t(),
    predicate: String.t(),
    object: String.t() | literal_value(),
    datatype: String.t() | nil,
    language: String.t() | nil,
    graph: String.t() | nil
  }
  
  @doc """
  Creates a new RDF statement.
  """
  def new(subject, predicate, object, opts \\ []) do
    datatype = Keyword.get(opts, :datatype)
    language = Keyword.get(opts, :language)
    graph = Keyword.get(opts, :graph)
    
    %__MODULE__{
      subject: subject,
      predicate: predicate,
      object: object,
      datatype: datatype,
      language: language,
      graph: graph
    }
  end
  
  @doc """
  Determines if the object is a literal value or a URI.
  """
  def object_is_literal?(%__MODULE__{object: object}) do
    not is_binary(object) or not Uri.is_absolute_uri?(object)
  end
  
  @doc """
  Resolves any relative URIs in the statement using a base URI.
  """
  def resolve_uris(%__MODULE__{} = statement, base_uri) do
    %__MODULE__{
      statement |
      subject: Uri.resolve(statement.subject, base_uri),
      predicate: Uri.resolve(statement.predicate, base_uri),
      object: resolve_object(statement.object, base_uri, statement.datatype),
      datatype: Uri.resolve(statement.datatype, base_uri),
      graph: Uri.resolve(statement.graph, base_uri)
    }
  end
  
  defp resolve_object(object, base_uri, _datatype) when is_binary(object) do
    if Uri.is_absolute_uri?(object) do
      object
    else
      Uri.resolve(object, base_uri)
    end
  end
  
  defp resolve_object(object, _base_uri, _datatype), do: object
  
  @doc """
  Converts the statement to a string representation.
  """
  def to_string(%__MODULE__{} = statement) do
    object_str = format_object(statement)
    graph_str = if statement.graph, do: " (graph: #{statement.graph})", else: ""
    
    "#{statement.subject} #{statement.predicate} #{object_str}#{graph_str} ."
  end
  
  defp format_object(%{object: object, datatype: datatype, language: language}) do
    cond do
      is_binary(object) and Uri.is_absolute_uri?(object) ->
        object
      is_binary(object) and language ->
        "\"#{object}\"@#{language}"
      is_binary(object) and datatype ->
        "\"#{object}\"^^#{datatype}"
      is_binary(object) ->
        "\"#{object}\""
      true ->
        "\"#{inspect(object)}\""
    end
  end
end