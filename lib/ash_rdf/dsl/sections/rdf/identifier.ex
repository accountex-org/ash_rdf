defmodule AshRdf.Dsl.Sections.Rdf.Identifier do
  @moduledoc """
  DSL section for defining RDF resource identifiers.
  
  Resources in RDF can have various identifiers including URIs and blank node IDs.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:identifier)
    desc("Defines an identifier for an RDF resource")
    
    option :uri, :string,
      doc: "The URI for this resource identifier"
      
    option :blank_node_id, :string,
      doc: "The blank node identifier"
  end
end