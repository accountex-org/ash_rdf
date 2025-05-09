defmodule AshRdf.Dsl.Sections.Rdfs do
  @moduledoc """
  DSL section for RDF Schema (RDFS) concepts.
  
  RDFS extends RDF with additional vocabulary for describing
  classes, subclasses, properties, domains, and ranges.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:rdfs)
    desc("Defines RDFS constructs like classes, subclasses, and property relationships.")

    sections([
      AshRdf.Dsl.Sections.Rdfs.Class,
      AshRdf.Dsl.Sections.Rdfs.PropertyDefinition
    ])
    
    # RDFS options
    option :allow_inference, :boolean, 
      default: true,
      doc: "Whether to allow RDFS inference (subclass/subproperty relationships)"
  end
end