defmodule AshRdf.Dsl.Sections.Rdf.Resource do
  @moduledoc """
  DSL section for defining RDF resources (subjects).
  
  Resources in RDF are identified by URIs and represent the entities described.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:resource)
    desc("Defines an RDF resource")
    
    has_many :identifiers, AshRdf.Dsl.Sections.Rdf.Identifier,
      default: [],
      doc: "Identifiers for this resource (URIs, blank nodes, etc.)"
    
    option :uri, :string,
      doc: "The URI for this resource (will be combined with base_uri if relative)"
    
    option :blank_node, :boolean,
      default: false,
      doc: "Whether this resource is a blank node"
      
    option :blank_node_id, :string,
      doc: "Optional identifier for blank nodes"
  end
end