defmodule AshRdf.Owl do
  @moduledoc """
  Main module for Web Ontology Language (OWL2) functionality in AshRdf.
  
  OWL2 extends RDFS with additional vocabulary for defining rich ontologies
  with complex class relationships, property characteristics, and constraints.
  """
  
  alias AshRdf.Owl.{Ontology, Class, Property, Individual, Restriction}
  alias AshRdf.Rdf.{Graph, Resource}
  
  @doc """
  Gets all OWL ontologies defined in a resource.
  """
  def ontologies(resource) do
    Ontology.ontologies(resource)
  end
  
  @doc """
  Gets the main OWL ontology defined in a resource.
  """
  def main_ontology(resource) do
    Ontology.main_ontology(resource)
  end
  
  @doc """
  Gets all OWL classes defined in a resource.
  """
  def classes(resource) do
    Class.classes(resource)
  end
  
  @doc """
  Gets a specific OWL class from a resource by name.
  """
  def class_by_name(resource, name) do
    Class.class_by_name(resource, name)
  end
  
  @doc """
  Gets all OWL properties defined in a resource.
  """
  def properties(resource) do
    Property.properties(resource)
  end
  
  @doc """
  Gets a specific OWL property from a resource by name.
  """
  def property_by_name(resource, name) do
    Property.property_by_name(resource, name)
  end
  
  @doc """
  Gets all OWL object properties in a resource.
  """
  def object_properties(resource) do
    Property.object_properties(resource)
  end
  
  @doc """
  Gets all OWL datatype properties in a resource.
  """
  def datatype_properties(resource) do
    Property.datatype_properties(resource)
  end
  
  @doc """
  Gets all OWL annotation properties in a resource.
  """
  def annotation_properties(resource) do
    Property.annotation_properties(resource)
  end
  
  @doc """
  Gets all OWL individuals defined in a resource.
  """
  def individuals(resource) do
    Individual.individuals(resource)
  end
  
  @doc """
  Gets a specific OWL individual from a resource by name.
  """
  def individual_by_name(resource, name) do
    Individual.individual_by_name(resource, name)
  end
  
  @doc """
  Gets all OWL restrictions defined in a resource.
  """
  def restrictions(resource) do
    Restriction.restrictions(resource)
  end
  
  @doc """
  Gets a specific OWL restriction from a resource by name.
  """
  def restriction_by_name(resource, name) do
    Restriction.restriction_by_name(resource, name)
  end
  
  @doc """
  Converts OWL constructs to RDF statements.
  """
  def to_rdf(resource) do
    # Combine statements from all OWL components
    Ontology.to_rdf(resource) ++
    Class.to_rdf(resource) ++
    Property.to_rdf(resource) ++
    Individual.to_rdf(resource) ++
    Restriction.to_rdf(resource)
  end
  
  @doc """
  Gets the OWL representation of an Ash resource as a graph.
  """
  def resource_to_graph(resource_module) do
    # Get statements from OWL definitions
    statements = to_rdf(resource_module)
    
    # Create a new graph with these statements
    namespaces = Resource.namespaces(resource_module)
    
    graph = Graph.new(namespaces: namespaces)
    
    Enum.reduce(statements, graph, fn statement, acc ->
      Graph.add(acc, statement)
    end)
  end
  
  @doc """
  Serializes OWL definitions to Turtle format.
  """
  def to_turtle(resource_module) do
    resource_module
    |> resource_to_graph()
    |> Graph.to_turtle()
  end
  
  @doc """
  Gets the OWL profile of a resource.
  """
  def profile(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:owl], :profile, :dl)
  end
  
  @doc """
  Checks if OWL reasoning is enabled for a resource.
  """
  def reasoning_enabled?(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:owl], :reasoning, true)
  end
end