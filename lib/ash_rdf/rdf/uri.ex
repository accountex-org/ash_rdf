defmodule AshRdf.Rdf.Uri do
  @moduledoc """
  Functions for handling RDF URIs and namespaces.
  """
  
  @doc """
  Resolves a possibly relative URI against a base URI.
  """
  def resolve(nil, _base_uri), do: nil
  def resolve(uri, nil), do: uri
  
  def resolve(uri, base_uri) do
    if is_absolute_uri?(uri) do
      uri
    else
      join_uri(base_uri, uri)
    end
  end
  
  @doc """
  Checks if a URI is absolute (starts with a scheme like http:, https:).
  """
  def is_absolute_uri?(uri) do
    uri && String.match?(uri, ~r/^[a-z][a-z0-9+.-]*:/i)
  end
  
  @doc """
  Joins a base URI with a relative URI path.
  """
  def join_uri(base_uri, relative_uri) do
    base_uri = String.trim_trailing(base_uri, "/")
    relative_uri = String.trim_leading(relative_uri, "/")
    
    "#{base_uri}/#{relative_uri}"
  end
  
  @doc """
  Extracts a local name from a URI.
  """
  def local_name(uri) do
    uri
    |> String.split("/")
    |> List.last()
    |> String.split("#")
    |> List.last()
  end
  
  @doc """
  Constructs a qname (qualified name) from a URI using a namespace map.
  """
  def to_qname(uri, namespaces) do
    Enum.find_value(namespaces, uri, fn {prefix, namespace} ->
      if String.starts_with?(uri, namespace) do
        local = String.replace_prefix(uri, namespace, "")
        "#{prefix}:#{local}"
      else
        nil
      end
    end)
  end
  
  @doc """
  Expands a qname into a full URI using a namespace map.
  """
  def from_qname(qname, namespaces) do
    case String.split(qname, ":", parts: 2) do
      [prefix, local] ->
        case Map.get(namespaces, prefix) do
          nil -> qname
          namespace -> namespace <> local
        end
      _ -> qname
    end
  end
end