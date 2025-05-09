defmodule AshRdf.Rdf.Resource do
  @moduledoc """
  Functions for handling RDF resources and their integration with Ash resources.
  """
  
  alias AshRdf.Rdf.{Statement, Uri}
  alias Spark.Dsl.Extension
  
  @doc """
  Gets the RDF base URI for an Ash resource.
  """
  def base_uri(resource) do
    Extension.get_opt(resource, [:rdf], :base_uri, nil)
  end
  
  @doc """
  Gets the RDF namespace prefix for an Ash resource.
  """
  def prefix(resource) do
    Extension.get_opt(resource, [:rdf], :prefix, nil)
  end
  
  @doc """
  Gets the namespace map for a resource.
  """
  def namespaces(resource) do
    # This would normally build a map of prefix -> namespace URI
    # For now, just include the resource's own namespace
    prefix = prefix(resource)
    base = base_uri(resource)
    
    base_namespaces = %{
      "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
      "owl" => "http://www.w3.org/2002/07/owl#",
      "xsd" => "http://www.w3.org/2001/XMLSchema#"
    }
    
    if prefix && base do
      Map.put(base_namespaces, prefix, base)
    else
      base_namespaces
    end
  end
  
  @doc """
  Builds the URI for a resource instance.
  """
  def uri_for_resource(resource, id) do
    base = base_uri(resource)
    "#{base}#{id}"
  end
  
  @doc """
  Extracts RDF statements from an Ash resource instance.
  """
  def to_rdf(resource_module, resource_instance) do
    id = Ash.Resource.Info.primary_key(resource_instance) |> List.first() |> Map.get(resource_instance)
    resource_uri = uri_for_resource(resource_module, id)
    
    # Get attributes as RDF statements
    attributes = Ash.Resource.Info.attributes(resource_module)
    
    attribute_statements = Enum.flat_map(attributes, fn attr ->
      attr_name = attr.name
      value = Map.get(resource_instance, attr_name)
      
      if value != nil do
        # Get the property URI from the attribute definition or build a default one
        property_uri = get_property_uri(resource_module, attr) || "#{base_uri(resource_module)}#{attr_name}"
        
        # Get datatype if defined or infer based on the value type
        datatype = get_datatype(attr, value)
        
        [Statement.new(resource_uri, property_uri, value, datatype: datatype)]
      else
        []
      end
    end)
    
    # Get relationships as RDF statements
    relationships = Ash.Resource.Info.relationships(resource_module)
    
    relationship_statements = Enum.flat_map(relationships, fn rel ->
      rel_name = rel.name
      related = Map.get(resource_instance, rel_name)
      
      if related != nil do
        # Get the property URI for the relationship or build a default one
        property_uri = get_relationship_uri(resource_module, rel) || "#{base_uri(resource_module)}#{rel_name}"
        
        case related do
          %_{} = related_instance ->
            # Single related record
            related_module = rel.destination
            related_id = Ash.Resource.Info.primary_key(related_instance) |> List.first() |> Map.get(related_instance)
            related_uri = uri_for_resource(related_module, related_id)
            
            [Statement.new(resource_uri, property_uri, related_uri)]
            
          related_instances when is_list(related_instances) ->
            # List of related records
            related_module = rel.destination
            
            Enum.map(related_instances, fn related_instance ->
              related_id = Ash.Resource.Info.primary_key(related_instance) |> List.first() |> Map.get(related_instance)
              related_uri = uri_for_resource(related_module, related_id)
              
              Statement.new(resource_uri, property_uri, related_uri)
            end)
            
          _ ->
            []
        end
      else
        []
      end
    end)
    
    # Combine all statements
    attribute_statements ++ relationship_statements
  end
  
  defp get_property_uri(resource_module, attribute) do
    # This would look for RDF property definitions in the DSL
    # For now, a simple implementation that returns nil (using default)
    nil
  end
  
  defp get_relationship_uri(resource_module, relationship) do
    # This would look for RDF property definitions for relationships in the DSL
    # For now, a simple implementation that returns nil (using default)
    nil
  end
  
  defp get_datatype(attribute, value) do
    # Get datatype from attribute definition or infer from value
    case attribute.type do
      :string -> "http://www.w3.org/2001/XMLSchema#string"
      :integer -> "http://www.w3.org/2001/XMLSchema#integer"
      :float -> "http://www.w3.org/2001/XMLSchema#float"
      :boolean -> "http://www.w3.org/2001/XMLSchema#boolean"
      :date -> "http://www.w3.org/2001/XMLSchema#date"
      :datetime -> "http://www.w3.org/2001/XMLSchema#dateTime"
      :utc_datetime -> "http://www.w3.org/2001/XMLSchema#dateTime"
      :naive_datetime -> "http://www.w3.org/2001/XMLSchema#dateTime"
      _ -> nil
    end
  end
  
  @doc """
  Creates a resource instance from RDF statements.
  """
  def from_rdf(resource_module, statements) do
    # Group statements by subject
    statements_by_subject = Enum.group_by(statements, & &1.subject)
    
    # This would create new Ash resource instances from the RDF data
    # Would need to match subject URIs to resources, predicates to attributes/relationships
    # For now, just a stub returning nil
    nil
  end
end