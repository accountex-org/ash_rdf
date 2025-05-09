defmodule AshRdf.Rdfs.Class do
  @moduledoc """
  Functions for working with RDFS classes.
  """
  
  alias Spark.Dsl.Extension
  alias AshRdf.Rdf.{Statement, Uri}
  
  @rdfs_namespace "http://www.w3.org/2000/01/rdf-schema#"
  @rdf_namespace "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  
  @doc """
  Gets all RDFS classes defined in a resource.
  """
  def classes(resource) do
    Extension.get_entities(resource, [:rdfs, :class])
  end
  
  @doc """
  Gets a specific RDFS class from a resource by name.
  """
  def class_by_name(resource, name) do
    classes(resource)
    |> Enum.find(&(&1.name == name))
  end
  
  @doc """
  Gets the URI for an RDFS class.
  """
  def class_uri(resource, class_entity) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    Uri.resolve(class_entity.uri || to_string(class_entity.name), base_uri)
  end
  
  @doc """
  Converts RDFS class definitions to RDF statements.
  """
  def to_rdf(resource) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    
    # Generate statements for each class
    Enum.flat_map(classes(resource), fn class_entity ->
      class_uri = class_uri(resource, class_entity)
      
      # Class type statement
      type_statement = Statement.new(
        class_uri,
        "#{@rdf_namespace}type",
        "#{@rdfs_namespace}Class"
      )
      
      # Label statement if present
      label_statements = if class_entity.label do
        [Statement.new(class_uri, "#{@rdfs_namespace}label", class_entity.label)]
      else
        []
      end
      
      # Comment statement if present
      comment_statements = if class_entity.comment do
        [Statement.new(class_uri, "#{@rdfs_namespace}comment", class_entity.comment)]
      else
        []
      end
      
      # See Also statement if present
      see_also_statements = if class_entity.see_also do
        see_also_uri = Uri.resolve(class_entity.see_also, base_uri)
        [Statement.new(class_uri, "#{@rdfs_namespace}seeAlso", see_also_uri)]
      else
        []
      end
      
      # Subclass relationships
      subclass_statements = Enum.map(class_entity.subclass_of, fn subclass_entity ->
        parent_uri = Uri.resolve(subclass_entity.class_uri, base_uri)
        Statement.new(class_uri, "#{@rdfs_namespace}subClassOf", parent_uri)
      end)
      
      # Combine all statements
      [type_statement] ++ label_statements ++ comment_statements ++ see_also_statements ++ subclass_statements
    end)
  end
  
  @doc """
  Gets all direct subclasses of a given class.
  """
  def direct_subclasses(resource, class_uri) do
    classes(resource)
    |> Enum.filter(fn class_entity ->
      Enum.any?(class_entity.subclass_of, fn subclass_entity ->
        parent_uri = AshRdf.Rdf.Resource.base_uri(resource)
        Uri.resolve(subclass_entity.class_uri, parent_uri) == class_uri
      end)
    end)
  end
  
  @doc """
  Gets all subclasses of a given class (direct and indirect).
  """
  def all_subclasses(resource, class_uri) do
    direct = direct_subclasses(resource, class_uri)
    
    # Recursively get subclasses of direct subclasses
    indirect = Enum.flat_map(direct, fn class_entity ->
      sub_uri = class_uri(resource, class_entity)
      all_subclasses(resource, sub_uri)
    end)
    
    direct ++ indirect
  end
  
  @doc """
  Gets all direct superclasses of a given class.
  """
  def direct_superclasses(resource, class_name) do
    class_entity = class_by_name(resource, class_name)
    
    if class_entity do
      Enum.map(class_entity.subclass_of, fn subclass_entity ->
        class_uri = subclass_entity.class_uri
        
        # Try to find the class entity by URI
        Enum.find(classes(resource), fn c ->
          c_uri = class_uri(resource, c)
          c_uri == class_uri
        end)
      end)
      |> Enum.reject(&is_nil/1)
    else
      []
    end
  end
  
  @doc """
  Gets all superclasses of a given class (direct and indirect).
  """
  def all_superclasses(resource, class_name) do
    direct = direct_superclasses(resource, class_name)
    
    # Recursively get superclasses of direct superclasses
    indirect = Enum.flat_map(direct, fn class_entity ->
      all_superclasses(resource, class_entity.name)
    end)
    
    direct ++ indirect
  end
  
  @doc """
  Determines if a class is a subclass of another class.
  """
  def is_subclass_of?(resource, class_name, potential_superclass_name) do
    superclasses = all_superclasses(resource, class_name)
    Enum.any?(superclasses, &(&1.name == potential_superclass_name))
  end
end