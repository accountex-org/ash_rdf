defmodule AshRdf.Dsl.Sections.Rdf do
  @moduledoc """
  DSL section for core RDF (Resource Description Framework) concepts.
  
  This section defines the basic RDF constructs:
  - Resources (subjects)
  - Properties (predicates)
  - Values (objects)
  - Statements (triples)
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:rdf)
    desc("Defines RDF resources, properties, and statements.")

    sections([
      AshRdf.Dsl.Sections.Rdf.Resource,
      AshRdf.Dsl.Sections.Rdf.Property,
      AshRdf.Dsl.Sections.Rdf.Statement
    ])
    
    # Core RDF options
    option :base_uri, :string, 
      required: true,
      doc: "The base URI for all resources defined in this module"
    
    option :prefix, :string,
      doc: "The preferred prefix for the base URI namespace"
    
    option :default_language, :string,
      default: "en",
      doc: "The default language tag for literal values when not specified"
  end
end