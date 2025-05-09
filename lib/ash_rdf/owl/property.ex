defmodule AshRdf.Owl.Property do
  @moduledoc """
  Functions for working with OWL properties.
  """
  
  alias Spark.Dsl.Extension
  alias AshRdf.Rdf.{Statement, Uri}
  
  @owl_namespace "http://www.w3.org/2002/07/owl#"
  @rdf_namespace "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  @rdfs_namespace "http://www.w3.org/2000/01/rdf-schema#"
  
  @doc """
  Gets all OWL properties defined in a resource.
  """
  def properties(resource) do
    Extension.get_entities(resource, [:owl, :property])
  end
  
  @doc """
  Gets a specific OWL property from a resource by name.
  """
  def property_by_name(resource, name) do
    properties(resource)
    |> Enum.find(&(&1.name == name))
  end
  
  @doc """
  Gets the URI for an OWL property.
  """
  def property_uri(resource, property_entity) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    Uri.resolve(property_entity.uri || to_string(property_entity.name), base_uri)
  end
  
  @doc """
  Converts OWL property definitions to RDF statements.
  """
  def to_rdf(resource) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    
    # Generate statements for each property
    Enum.flat_map(properties(resource), fn property_entity ->
      property_uri = property_uri(resource, property_entity)
      
      # Property type statement based on property type
      type_statements = case property_entity.type do
        :object_property -> 
          [Statement.new(property_uri, "#{@rdf_namespace}type", "#{@owl_namespace}ObjectProperty")]
        :datatype_property -> 
          [Statement.new(property_uri, "#{@rdf_namespace}type", "#{@owl_namespace}DatatypeProperty")]
        :annotation_property -> 
          [Statement.new(property_uri, "#{@rdf_namespace}type", "#{@owl_namespace}AnnotationProperty")]
      end
      
      # Domain statement if present
      domain_statements = if property_entity.domain do
        domain_uri = Uri.resolve(property_entity.domain, base_uri)
        [Statement.new(property_uri, "#{@rdfs_namespace}domain", domain_uri)]
      else
        []
      end
      
      # Range statement if present
      range_statements = if property_entity.range do
        range_uri = Uri.resolve(property_entity.range, base_uri)
        [Statement.new(property_uri, "#{@rdfs_namespace}range", range_uri)]
      else
        []
      end
      
      # Label statement if present
      label_statements = if property_entity.label do
        [Statement.new(property_uri, "#{@rdfs_namespace}label", property_entity.label)]
      else
        []
      end
      
      # Comment statement if present
      comment_statements = if property_entity.comment do
        [Statement.new(property_uri, "#{@rdfs_namespace}comment", property_entity.comment)]
      else
        []
      end
      
      # Equivalent property relationships
      equivalent_property_statements = Enum.map(property_entity.equivalent_to, fn equivalent_entity ->
        eq_uri = Uri.resolve(equivalent_entity.property_uri, base_uri)
        Statement.new(property_uri, "#{@owl_namespace}equivalentProperty", eq_uri)
      end)
      
      # Inverse property relationships
      inverse_property_statements = Enum.map(property_entity.inverse_of, fn inverse_entity ->
        inv_uri = Uri.resolve(inverse_entity.property_uri, base_uri)
        Statement.new(property_uri, "#{@owl_namespace}inverseOf", inv_uri)
      end)
      
      # Property characteristics
      characteristic_statements = []
      
      # Functional
      characteristic_statements = if property_entity.functional do
        [Statement.new(property_uri, "#{@rdf_namespace}type", "#{@owl_namespace}FunctionalProperty") | characteristic_statements]
      else
        characteristic_statements
      end
      
      # Inverse functional (only for object properties)
      characteristic_statements = if property_entity.inverse_functional && property_entity.type == :object_property do
        [Statement.new(property_uri, "#{@rdf_namespace}type", "#{@owl_namespace}InverseFunctionalProperty") | characteristic_statements]
      else
        characteristic_statements
      end
      
      # Transitive (only for object properties)
      characteristic_statements = if property_entity.transitive && property_entity.type == :object_property do
        [Statement.new(property_uri, "#{@rdf_namespace}type", "#{@owl_namespace}TransitiveProperty") | characteristic_statements]
      else
        characteristic_statements
      end
      
      # Symmetric (only for object properties)
      characteristic_statements = if property_entity.symmetric && property_entity.type == :object_property do
        [Statement.new(property_uri, "#{@rdf_namespace}type", "#{@owl_namespace}SymmetricProperty") | characteristic_statements]
      else
        characteristic_statements
      end
      
      # Asymmetric (only for object properties)
      characteristic_statements = if property_entity.asymmetric && property_entity.type == :object_property do
        [Statement.new(property_uri, "#{@rdf_namespace}type", "#{@owl_namespace}AsymmetricProperty") | characteristic_statements]
      else
        characteristic_statements
      end
      
      # Reflexive (only for object properties)
      characteristic_statements = if property_entity.reflexive && property_entity.type == :object_property do
        [Statement.new(property_uri, "#{@rdf_namespace}type", "#{@owl_namespace}ReflexiveProperty") | characteristic_statements]
      else
        characteristic_statements
      end
      
      # Irreflexive (only for object properties)
      characteristic_statements = if property_entity.irreflexive && property_entity.type == :object_property do
        [Statement.new(property_uri, "#{@rdf_namespace}type", "#{@owl_namespace}IrreflexiveProperty") | characteristic_statements]
      else
        characteristic_statements
      end
      
      # Deprecated flag
      deprecated_statements = if property_entity.deprecated do
        [Statement.new(property_uri, "#{@owl_namespace}deprecated", "true", datatype: "#{@rdf_namespace}boolean")]
      else
        []
      end
      
      # Combine all statements
      type_statements ++ domain_statements ++ range_statements ++ 
        label_statements ++ comment_statements ++ 
        equivalent_property_statements ++ inverse_property_statements ++
        characteristic_statements ++ deprecated_statements
    end)
  end
  
  @doc """
  Gets all object properties in a resource.
  """
  def object_properties(resource) do
    properties(resource)
    |> Enum.filter(&(&1.type == :object_property))
  end
  
  @doc """
  Gets all datatype properties in a resource.
  """
  def datatype_properties(resource) do
    properties(resource)
    |> Enum.filter(&(&1.type == :datatype_property))
  end
  
  @doc """
  Gets all annotation properties in a resource.
  """
  def annotation_properties(resource) do
    properties(resource)
    |> Enum.filter(&(&1.type == :annotation_property))
  end
  
  @doc """
  Gets all properties with a given characteristic.
  """
  def properties_with_characteristic(resource, characteristic) do
    properties(resource)
    |> Enum.filter(&(Map.get(&1, characteristic) == true))
  end
end