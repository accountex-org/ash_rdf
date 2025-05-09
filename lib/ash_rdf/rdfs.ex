defmodule AshRdf.Rdfs do
  @moduledoc """
  Main module for RDF Schema (RDFS) functionality in AshRdf.
  
  RDFS extends RDF with vocabulary for describing classes, properties, domains, ranges,
  and subclass/subproperty relationships.
  """
  
  alias AshRdf.Rdfs.{Class, Property, Inference}
  alias AshRdf.Rdf.{Graph, Resource}
  
  @doc """
  Gets all RDFS classes defined in a resource.
  """
  def classes(resource) do
    Class.classes(resource)
  end
  
  @doc """
  Gets a specific RDFS class from a resource by name.
  """
  def class_by_name(resource, name) do
    Class.class_by_name(resource, name)
  end
  
  @doc """
  Gets all RDFS properties defined in a resource.
  """
  def properties(resource) do
    Property.properties(resource)
  end
  
  @doc """
  Gets a specific RDFS property from a resource by name.
  """
  def property_by_name(resource, name) do
    Property.property_by_name(resource, name)
  end
  
  @doc """
  Converts RDFS constructs to RDF statements.
  """
  def to_rdf(resource) do
    # Combine class and property statements
    Class.to_rdf(resource) ++ Property.to_rdf(resource)
  end
  
  @doc """
  Gets all direct subclasses of a given class.
  """
  def direct_subclasses(resource, class_uri) do
    Class.direct_subclasses(resource, class_uri)
  end
  
  @doc """
  Gets all subclasses of a given class (direct and indirect).
  """
  def all_subclasses(resource, class_uri) do
    Class.all_subclasses(resource, class_uri)
  end
  
  @doc """
  Determines if a class is a subclass of another class.
  """
  def is_subclass_of?(resource, class_name, potential_superclass_name) do
    Class.is_subclass_of?(resource, class_name, potential_superclass_name)
  end
  
  @doc """
  Gets all direct subproperties of a given property.
  """
  def direct_subproperties(resource, property_uri) do
    Property.direct_subproperties(resource, property_uri)
  end
  
  @doc """
  Gets all subproperties of a given property (direct and indirect).
  """
  def all_subproperties(resource, property_uri) do
    Property.all_subproperties(resource, property_uri)
  end
  
  @doc """
  Determines if a property is a subproperty of another property.
  """
  def is_subproperty_of?(resource, property_name, potential_superproperty_name) do
    Property.is_subproperty_of?(resource, property_name, potential_superproperty_name)
  end
  
  @doc """
  Gets all properties with a given domain.
  """
  def properties_with_domain(resource, domain_uri) do
    Property.properties_with_domain(resource, domain_uri)
  end
  
  @doc """
  Gets all properties with a given range.
  """
  def properties_with_range(resource, range_uri) do
    Property.properties_with_range(resource, range_uri)
  end
  
  @doc """
  Applies RDFS inference rules to a graph.
  """
  def apply_inference(%Graph{} = graph) do
    Inference.apply_inference(graph)
  end
  
  @doc """
  Gets the RDFS representation of an Ash resource as a graph.
  """
  def resource_to_graph(resource_module) do
    # Get statements from RDFS definitions
    statements = to_rdf(resource_module)
    
    # Create a new graph with these statements
    namespaces = Resource.namespaces(resource_module)
    
    graph = Graph.new(namespaces: namespaces)
    
    Enum.reduce(statements, graph, fn statement, acc ->
      Graph.add(acc, statement)
    end)
  end
  
  @doc """
  Serializes RDFS definitions to Turtle format.
  """
  def to_turtle(resource_module) do
    resource_module
    |> resource_to_graph()
    |> Graph.to_turtle()
  end
end