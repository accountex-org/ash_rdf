defmodule AshRdf.Rdf.Serializer do
  @moduledoc """
  Provides serialization of RDF data to various formats.
  """
  
  alias AshRdf.Rdf.Statement
  
  @doc """
  Serializes a list of RDF statements to Turtle format.
  """
  def to_turtle(statements, namespaces \\ %{}) do
    # Generate prefix declarations
    prefix_declarations = Enum.map_join(namespaces, "\n", fn {prefix, uri} ->
      "@prefix #{prefix}: <#{uri}> ."
    end)
    
    # Group statements by subject for more compact representation
    statements_by_subject = Enum.group_by(statements, & &1.subject)
    
    # Format each subject with its predicates and objects
    subjects_turtle = Enum.map_join(statements_by_subject, "\n\n", fn {subject, subj_statements} ->
      # Group by predicate for even more compact representation
      by_predicate = Enum.group_by(subj_statements, & &1.predicate)
      
      predicates_turtle = Enum.map_join(by_predicate, " ;\n    ", fn {predicate, pred_statements} ->
        objects = Enum.map_join(pred_statements, ", ", fn statement ->
          format_object(statement)
        end)
        
        "#{format_predicate(predicate)} #{objects}"
      end)
      
      "<#{subject}> #{predicates_turtle} ."
    end)
    
    "#{prefix_declarations}\n\n#{subjects_turtle}\n"
  end
  
  defp format_predicate(predicate) do
    "<#{predicate}>"
  end
  
  defp format_object(%Statement{} = statement) do
    if Statement.object_is_literal?(statement) do
      format_literal(statement.object, statement.datatype, statement.language)
    else
      "<#{statement.object}>"
    end
  end
  
  defp format_literal(value, datatype, language) when is_binary(value) do
    cond do
      language ->
        "\"#{escape_string(value)}\"@#{language}"
      datatype ->
        "\"#{escape_string(value)}\"^^<#{datatype}>"
      true ->
        "\"#{escape_string(value)}\""
    end
  end
  
  defp format_literal(value, datatype, _language) do
    if datatype do
      "\"#{value}\"^^<#{datatype}>"
    else
      "\"#{value}\""
    end
  end
  
  defp escape_string(string) do
    string
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
    |> String.replace("\t", "\\t")
  end
  
  @doc """
  Serializes a list of RDF statements to N-Triples format.
  """
  def to_ntriples(statements) do
    Enum.map_join(statements, "\n", fn statement ->
      subject = "<#{statement.subject}>"
      predicate = "<#{statement.predicate}>"
      
      object = if Statement.object_is_literal?(statement) do
        format_literal(statement.object, statement.datatype, statement.language)
      else
        "<#{statement.object}>"
      end
      
      "#{subject} #{predicate} #{object} ."
    end)
  end
  
  @doc """
  Serializes a list of RDF statements to JSON-LD format.
  """
  def to_jsonld(statements, context \\ %{}) do
    # Basic JSON-LD implementation - would be more complex in practice
    
    # Group statements by subject
    statements_by_subject = Enum.group_by(statements, & &1.subject)
    
    # Create a JSON-LD document for each subject
    nodes = Enum.map(statements_by_subject, fn {subject, subj_statements} ->
      # Create basic node with id (subject)
      node = %{"@id" => subject}
      
      # Add properties
      node_with_props = Enum.reduce(subj_statements, node, fn statement, acc ->
        value = if Statement.object_is_literal?(statement) do
          object = %{"@value" => statement.object}
          
          object = if statement.language, do: Map.put(object, "@language", statement.language), else: object
          object = if statement.datatype, do: Map.put(object, "@type", statement.datatype), else: object
          
          object
        else
          %{"@id" => statement.object}
        end
        
        # Add to existing property or create new one
        Map.update(acc, statement.predicate, value, fn existing ->
          case existing do
            list when is_list(list) -> [value | list]
            existing -> [value, existing]
          end
        end)
      end)
      
      node_with_props
    end)
    
    # Create final JSON-LD document
    result = %{
      "@context" => context,
      "@graph" => nodes
    }
    
    # This is simple string formatting - a real implementation would use Poison or Jason
    Jason.encode!(result, pretty: true)
  rescue
    # If Jason is not available, fall back to a simple string representation
    _ ->
      inspect(result, pretty: true)
  end
end