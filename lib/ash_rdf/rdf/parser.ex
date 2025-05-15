defmodule AshRdf.Rdf.Parser do
  @moduledoc """
  Provides parsing of RDF data from various formats.
  """
  
  alias AshRdf.Rdf.Statement
  
  @doc """
  Parses RDF data from Turtle format.
  
  Note: This is a simplified parser that handles basic Turtle syntax.
  A full implementation would need to handle more complex Turtle features.
  """
  def parse_turtle(turtle_string) do
    # Extract prefixes
    prefixes = extract_prefixes(turtle_string)
    
    # Process triples
    turtle_string
    |> remove_prefix_declarations()
    |> String.split(".")
    |> Enum.flat_map(&parse_turtle_statement(&1, prefixes))
  end
  
  defp extract_prefixes(turtle_string) do
    prefix_regex = ~r/@prefix\s+(\w+):\s+<([^>]+)>\s*\./
    
    Regex.scan(prefix_regex, turtle_string)
    |> Enum.map(fn [_, prefix, uri] -> {prefix, uri} end)
    |> Map.new()
  end
  
  defp remove_prefix_declarations(turtle_string) do
    String.replace(turtle_string, ~r/@prefix\s+\w+:\s+<[^>]+>\s*\./, "")
  end
  
  defp parse_turtle_statement(statement_str, prefixes) do
    statement_str = String.trim(statement_str)
    
    if statement_str == "" do
      []
    else
      case String.split(statement_str, " ", parts: 3) do
        [subject, predicate, object] ->
          subject = normalize_uri(subject, prefixes)
          predicate = normalize_uri(predicate, prefixes)
          
          # Parse object (could be URI or literal)
          {object_value, datatype, language} = parse_object(object, prefixes)
          
          [Statement.new(subject, predicate, object_value, datatype: datatype, language: language)]
        _ ->
          []
      end
    end
  end
  
  defp normalize_uri(uri_str, prefixes) do
    uri_str = String.trim(uri_str)
    
    cond do
      # Full URI
      String.starts_with?(uri_str, "<") and String.ends_with?(uri_str, ">") ->
        uri_str |> String.slice(1, String.length(uri_str) - 2)
        
      # Prefixed name
      String.contains?(uri_str, ":") ->
        [prefix, local] = String.split(uri_str, ":", parts: 2)
        case Map.get(prefixes, prefix) do
          nil -> uri_str  # Unknown prefix, return as is
          namespace -> namespace <> local
        end
        
      # Something else
      true ->
        uri_str
    end
  end
  
  defp parse_object(object_str, prefixes) do
    object_str = String.trim(object_str)
    
    cond do
      # URI
      String.starts_with?(object_str, "<") and String.ends_with?(object_str, ">") ->
        {normalize_uri(object_str, prefixes), nil, nil}
        
      # Prefixed name
      String.contains?(object_str, ":") ->
        {normalize_uri(object_str, prefixes), nil, nil}
        
      # Language tagged string
      String.match?(object_str, ~r/"[^"]*"@\w+/) ->
        [value, lang] = String.split(object_str, "@")
        value = value |> String.slice(1, String.length(value) - 2) |> unescape_string()
        {value, nil, lang}
        
      # Datatyped literal
      String.match?(object_str, ~r/"[^"]*"\^\^/) ->
        [value, datatype] = String.split(object_str, "^^")
        value = value |> String.slice(1, String.length(value) - 2) |> unescape_string()
        datatype = normalize_uri(datatype, prefixes)
        {value, datatype, nil}
        
      # Plain literal
      String.starts_with?(object_str, "\"") and String.ends_with?(object_str, "\"") ->
        {object_str |> String.slice(1, String.length(object_str) - 2) |> unescape_string(), nil, nil}
        
      # Something else
      true ->
        {object_str, nil, nil}
    end
  end
  
  defp unescape_string(string) do
    string
    |> String.replace("\\\"", "\"")
    |> String.replace("\\\\", "\\")
    |> String.replace("\\n", "\n")
    |> String.replace("\\r", "\r")
    |> String.replace("\\t", "\t")
  end
  
  @doc """
  Parses RDF data from N-Triples format.
  """
  def parse_ntriples(ntriples_string) do
    ntriples_string
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(String.starts_with?(&1, "#") or &1 == ""))
    |> Enum.flat_map(fn line ->
      case String.split(line, " ", parts: 4) do
        [subject, predicate, object, "."] ->
          subject = subject |> String.trim_leading("<") |> String.trim_trailing(">")
          predicate = predicate |> String.trim_leading("<") |> String.trim_trailing(">")
          
          {object_value, datatype, language} = parse_ntriples_object(object)
          
          [Statement.new(subject, predicate, object_value, datatype: datatype, language: language)]
        _ ->
          []
      end
    end)
  end
  
  defp parse_ntriples_object(object_str) do
    cond do
      # URI
      String.starts_with?(object_str, "<") and String.ends_with?(object_str, ">") ->
        {object_str |> String.trim_leading("<") |> String.trim_trailing(">"), nil, nil}
        
      # Language tagged string
      String.match?(object_str, ~r/"[^"]*"@\w+/) ->
        [value, lang] = String.split(object_str, "@")
        value = value |> String.slice(1, String.length(value) - 2) |> unescape_string()
        {value, nil, lang}
        
      # Datatyped literal
      String.match?(object_str, ~r/"[^"]*"\^\^/) ->
        [value, datatype] = String.split(object_str, "^^")
        value = value |> String.slice(1, String.length(value) - 2) |> unescape_string()
        datatype = datatype |> String.trim_leading("<") |> String.trim_trailing(">")
        {value, datatype, nil}
        
      # Plain literal
      String.starts_with?(object_str, "\"") and String.ends_with?(object_str, "\"") ->
        {object_str |> String.slice(1, String.length(object_str) - 2) |> unescape_string(), nil, nil}
        
      # Something else
      true ->
        {object_str, nil, nil}
    end
  end
end