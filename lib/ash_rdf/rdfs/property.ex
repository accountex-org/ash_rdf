defmodule AshRdf.Rdfs.Property do
  @moduledoc """
  Functions for working with RDFS properties.
  """
  
  alias Spark.Dsl.Extension
  alias AshRdf.Rdf.{Statement, Uri}
  
  @rdfs_namespace "http://www.w3.org/2000/01/rdf-schema#"
  @rdf_namespace "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  
  @doc """
  Gets all RDFS properties defined in a resource.
  """
  def properties(resource) do
    Extension.get_entities(resource, [:rdfs, :property])
  end
  
  @doc """
  Gets a specific RDFS property from a resource by name.
  """
  def property_by_name(resource, name) do
    properties(resource)
    |> Enum.find(&(&1.name == name))
  end
  
  @doc """
  Gets the URI for an RDFS property.
  """
  def property_uri(resource, property_entity) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    Uri.resolve(property_entity.uri || to_string(property_entity.name), base_uri)
  end
  
  @doc """
  Converts RDFS property definitions to RDF statements.
  """
  def to_rdf(resource) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    
    # Generate statements for each property
    Enum.flat_map(properties(resource), fn property_entity ->
      property_uri = property_uri(resource, property_entity)
      
      # Property type statement
      type_statement = Statement.new(
        property_uri,
        "#{@rdf_namespace}type",
        "#{@rdf_namespace}Property"
      )
      
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
      
      # Subproperty relationships
      subproperty_statements = Enum.map(property_entity.subproperty_of, fn subproperty_entity ->
        parent_uri = Uri.resolve(subproperty_entity.property_uri, base_uri)
        Statement.new(property_uri, "#{@rdfs_namespace}subPropertyOf", parent_uri)
      end)
      
      # Combine all statements
      [type_statement] ++ domain_statements ++ range_statements ++ 
      label_statements ++ comment_statements ++ subproperty_statements
    end)
  end
  
  @doc """
  Gets all direct subproperties of a given property.
  """
  def direct_subproperties(resource, property_uri) do
    properties(resource)
    |> Enum.filter(fn property_entity ->
      Enum.any?(property_entity.subproperty_of, fn subproperty_entity ->
        parent_uri = AshRdf.Rdf.Resource.base_uri(resource)
        Uri.resolve(subproperty_entity.property_uri, parent_uri) == property_uri
      end)
    end)
  end
  
  @doc """
  Gets all subproperties of a given property (direct and indirect).
  """
  def all_subproperties(resource, property_uri) do
    direct = direct_subproperties(resource, property_uri)
    
    # Recursively get subproperties of direct subproperties
    indirect = Enum.flat_map(direct, fn property_entity ->
      sub_uri = property_uri(resource, property_entity)
      all_subproperties(resource, sub_uri)
    end)
    
    direct ++ indirect
  end
  
  @doc """
  Gets all direct superproperties of a given property.
  """
  def direct_superproperties(resource, property_name) do
    property_entity = property_by_name(resource, property_name)
    
    if property_entity do
      Enum.map(property_entity.subproperty_of, fn subproperty_entity ->
        property_uri = subproperty_entity.property_uri
        
        # Try to find the property entity by URI
        Enum.find(properties(resource), fn p ->
          p_uri = property_uri(resource, p)
          p_uri == property_uri
        end)
      end)
      |> Enum.reject(&is_nil/1)
    else
      []
    end
  end
  
  @doc """
  Gets all superproperties of a given property (direct and indirect).
  """
  def all_superproperties(resource, property_name) do
    direct = direct_superproperties(resource, property_name)
    
    # Recursively get superproperties of direct superproperties
    indirect = Enum.flat_map(direct, fn property_entity ->
      all_superproperties(resource, property_entity.name)
    end)
    
    direct ++ indirect
  end
  
  @doc """
  Determines if a property is a subproperty of another property.
  """
  def is_subproperty_of?(resource, property_name, potential_superproperty_name) do
    superproperties = all_superproperties(resource, property_name)
    Enum.any?(superproperties, &(&1.name == potential_superproperty_name))
  end
  
  @doc """
  Gets all properties with a given domain.
  """
  def properties_with_domain(resource, domain_uri) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    
    properties(resource)
    |> Enum.filter(fn property_entity ->
      if property_entity.domain do
        resolved_domain = Uri.resolve(property_entity.domain, base_uri)
        resolved_domain == domain_uri
      else
        false
      end
    end)
  end
  
  @doc """
  Gets all properties with a given range.
  """
  def properties_with_range(resource, range_uri) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    
    properties(resource)
    |> Enum.filter(fn property_entity ->
      if property_entity.range do
        resolved_range = Uri.resolve(property_entity.range, base_uri)
        resolved_range == range_uri
      else
        false
      end
    end)
  end
end