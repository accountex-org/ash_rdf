defmodule AshRdf.Sparql.ResponseParser do
  @moduledoc """
  Parses SPARQL query results into Ash resources.
  
  This module handles parsing of SPARQL JSON, XML, and CSV formats,
  converting them to Ash resource instances. It also provides utilities
  for handling RDF serialization formats like Turtle and N-Triples.
  """

  alias Ash.Resource

  @doc """
  Parse SPARQL SELECT query results into Ash resource instances.
  """
  @spec parse_select_results(map() | binary(), Ash.Resource.t(), keyword()) :: 
    {:ok, [Ash.Resource.record()]} | {:error, term()}
  def parse_select_results(results, resource, options \\ [])

  def parse_select_results(%{"results" => %{"bindings" => bindings}}, resource, options) do
    # Parse JSON format results
    records = Enum.map(bindings, &parse_json_binding(&1, resource))
    {:ok, records}
  end

  def parse_select_results(results, resource, options) when is_binary(results) do
    # Try to detect format and parse accordingly
    cond do
      String.starts_with?(results, "<?xml") || String.starts_with?(results, "<sparql") ->
        parse_xml_results(results, resource, options)
        
      String.starts_with?(results, "s,p,o") || String.starts_with?(results, "subject,predicate,object") ->
        parse_csv_results(results, resource, options)
        
      true ->
        {:error, {:unrecognized_format, results}}
    end
  end

  @doc """
  Parse SPARQL CONSTRUCT query results into Ash resource instances.
  """
  @spec parse_construct_results(binary(), Ash.Resource.t(), atom(), keyword()) :: 
    {:ok, [Ash.Resource.record()]} | {:error, term()}
  def parse_construct_results(results, resource, format, options \\ []) do
    # Convert format to parser module
    parser_mod = case format do
      :turtle -> AshRdf.Rdf.Parser.Turtle
      :ntriples -> AshRdf.Rdf.Parser.NTriples
      :jsonld -> AshRdf.Rdf.Parser.JsonLd
      _ -> AshRdf.Rdf.Parser.Turtle  # Default
    end
    
    # Parse RDF data into a graph
    with {:ok, graph} <- parser_mod.parse(results),
         {:ok, records} <- graph_to_resources(graph, resource) do
      {:ok, records}
    else
      error -> error
    end
  end

  @doc """
  Parse SPARQL ASK query results.
  """
  @spec parse_ask_results(map() | binary(), keyword()) :: 
    {:ok, boolean()} | {:error, term()}
  def parse_ask_results(results, options \\ [])

  def parse_ask_results(%{"boolean" => boolean}, _options) when is_boolean(boolean) do
    # JSON format
    {:ok, boolean}
  end

  def parse_ask_results(results, options) when is_binary(results) do
    # Try to detect format and parse accordingly
    cond do
      String.starts_with?(results, "<?xml") || String.starts_with?(results, "<sparql") ->
        parse_xml_ask_results(results, options)
        
      true ->
        {:error, {:unrecognized_format, results}}
    end
  end

  @doc """
  Parse a JSON result binding into a resource instance.
  """
  @spec parse_json_binding(map(), Ash.Resource.t()) :: Ash.Resource.record()
  def parse_json_binding(binding, resource) do
    # Extract the subject URI
    subject_uri = 
      case binding do
        %{"s" => %{"value" => uri, "type" => "uri"}} -> uri
        _ -> nil
      end
    
    # Extract property values and build a record
    attrs = 
      resource
      |> Resource.Info.attributes()
      |> Enum.reduce(%{}, fn %{name: name}, acc ->
        attr_value = extract_attribute_value(binding, name)
        if attr_value do
          Map.put(acc, name, attr_value)
        else
          acc
        end
      end)
    
    # Set the primary key if not present
    attrs = 
      if subject_uri && !Map.has_key?(attrs, primary_key_name(resource)) do
        pk_value = extract_id_from_uri(subject_uri, resource)
        Map.put(attrs, primary_key_name(resource), pk_value)
      else
        attrs
      end
    
    # Build the resource struct
    struct(resource, attrs)
  end

  # Private helpers

  defp primary_key_name(resource) do
    resource
    |> Resource.Info.primary_key()
    |> List.first()
  end

  defp extract_id_from_uri(uri, resource) do
    base_uri = AshRdf.Dsl.Info.base_uri(resource)
    
    if String.starts_with?(uri, base_uri) do
      uri
      |> String.replace_prefix(base_uri, "")
      |> String.trim("/")
      |> parse_id_value(primary_key_type(resource))
    else
      uri
    end
  end

  defp primary_key_type(resource) do
    pk_name = primary_key_name(resource)
    
    resource
    |> Resource.Info.attributes()
    |> Enum.find(fn %{name: name} -> name == pk_name end)
    |> case do
      %{type: type} -> type
      _ -> :string
    end
  end

  defp parse_id_value(value, :integer), do: String.to_integer(value)
  defp parse_id_value(value, :uuid), do: value
  defp parse_id_value(value, _), do: value

  defp extract_attribute_value(binding, attr_name) do
    # First try the direct attribute name
    case binding do
      %{^attr_name => value} -> parse_rdf_value(value)
      _ -> 
        # Next try alternative name formats
        attr_str = to_string(attr_name)
        case binding do
          %{^attr_str => value} -> parse_rdf_value(value)
          _ -> nil
        end
    end
  end

  defp parse_rdf_value(%{"value" => value, "type" => type}) do
    case type do
      "uri" -> value
      "literal" -> value
      "typed-literal" -> parse_typed_literal(value, Map.get(%{"datatype" => datatype}))
      _ -> value
    end
  end

  defp parse_rdf_value(value), do: value

  defp parse_typed_literal(value, datatype) do
    case datatype do
      "http://www.w3.org/2001/XMLSchema#integer" -> String.to_integer(value)
      "http://www.w3.org/2001/XMLSchema#decimal" -> String.to_float(value)
      "http://www.w3.org/2001/XMLSchema#boolean" -> value == "true"
      "http://www.w3.org/2001/XMLSchema#dateTime" -> parse_datetime(value)
      "http://www.w3.org/2001/XMLSchema#date" -> parse_date(value)
      _ -> value
    end
  end

  defp parse_datetime(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _} -> datetime
      _ -> value
    end
  end

  defp parse_date(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> value
    end
  end

  defp parse_xml_results(xml_string, resource, options) do
    try do
      import SweetXml
      
      # Parse results with SweetXml
      results = 
        xml_string
        |> xpath(
          ~x"//results/result"l,
          bindings: ~x"./binding"l,
          binding_name: ~x"./@name"s,
          binding_value: ~x"./uri|./literal/text()"s,
          binding_type: ~x"name(./*[1])"s
        )
      
      # Convert to format similar to JSON bindings
      bindings = 
        results 
        |> Enum.map(fn result ->
          Enum.reduce(result.bindings, %{}, fn binding, acc ->
            name = binding.binding_name
            value = %{
              "value" => binding.binding_value,
              "type" => case binding.binding_type do
                "uri" -> "uri"
                "literal" -> "literal"
                _ -> "literal"
              end
            }
            Map.put(acc, name, value)
          end)
        end)
      
      # Parse bindings into resources
      records = Enum.map(bindings, &parse_json_binding(&1, resource))
      {:ok, records}
    rescue
      e -> {:error, {:xml_parse_error, e}}
    end
  end

  defp parse_csv_results(csv_string, resource, options) do
    try do
      # Parse CSV
      [headers | rows] = 
        csv_string
        |> String.split("\n")
        |> Enum.map(&String.split(&1, ","))
        |> Enum.filter(fn row -> length(row) > 0 end)
      
      # Convert to format similar to JSON bindings
      bindings = 
        rows
        |> Enum.map(fn row ->
          Enum.zip(headers, row)
          |> Enum.reduce(%{}, fn {header, value}, acc ->
            # Detect if the value is a URI
            {type, clean_value} = 
              cond do
                String.starts_with?(value, "<") && String.ends_with?(value, ">") ->
                  {"uri", String.slice(value, 1..-2)}
                String.starts_with?(value, "\"") && String.ends_with?(value, "\"") ->
                  {"literal", String.slice(value, 1..-2)}
                true ->
                  {"literal", value}
              end
            
            Map.put(acc, header, %{"value" => clean_value, "type" => type})
          end)
        end)
      
      # Parse bindings into resources
      records = Enum.map(bindings, &parse_json_binding(&1, resource))
      {:ok, records}
    rescue
      e -> {:error, {:csv_parse_error, e}}
    end
  end

  defp parse_xml_ask_results(xml_string, _options) do
    try do
      import SweetXml
      
      # Extract boolean result
      result = 
        xml_string
        |> xpath(~x"//boolean/text()"s)
        |> String.downcase()
        |> case do
          "true" -> true
          _ -> false
        end
      
      {:ok, result}
    rescue
      e -> {:error, {:xml_parse_error, e}}
    end
  end

  defp graph_to_resources(graph, resource) do
    # Extract RDF schema information for the resource
    class_uri = AshRdf.Dsl.Info.class_uri(resource)
    
    # Find subjects with rdf:type matching the resource class
    subjects = 
      graph
      |> AshRdf.Rdf.Graph.query({:predicate, "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"}, 
                                {:object, class_uri})
      |> Enum.map(fn {subject, _, _} -> subject end)
    
    # For each subject, extract properties and build a resource instance
    records = 
      subjects
      |> Enum.map(fn subject ->
        attrs = 
          resource
          |> Resource.Info.attributes()
          |> Enum.reduce(%{}, fn %{name: name}, acc ->
            # Get the URI for this attribute
            predicate = AshRdf.Dsl.Info.property_uri(resource, name)
            
            # Query the graph for this subject-predicate pair
            values = 
              graph
              |> AshRdf.Rdf.Graph.query({:subject, subject}, {:predicate, predicate})
              |> Enum.map(fn {_, _, object} -> parse_graph_value(object) end)
            
            # Use the first value (or nil if none)
            value = List.first(values)
            
            if value do
              Map.put(acc, name, value)
            else
              acc
            end
          end)
        
        # Set the ID based on the subject URI
        attrs = 
          if !Map.has_key?(attrs, primary_key_name(resource)) do
            pk_value = extract_id_from_uri(subject, resource)
            Map.put(attrs, primary_key_name(resource), pk_value)
          else
            attrs
          end
        
        struct(resource, attrs)
      end)
    
    {:ok, records}
  end

  defp parse_graph_value({:uri, uri}), do: uri
  defp parse_graph_value({:literal, value}), do: value
  defp parse_graph_value({:typed_literal, value, datatype}), do: parse_typed_literal(value, datatype)
  defp parse_graph_value(value), do: value
end