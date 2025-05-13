defmodule AshRdf.Dsl.Sections.Rdfs do
  @moduledoc """
  DSL section for RDF Schema (RDFS) concepts.
  
  RDFS extends RDF with additional vocabulary for describing
  classes, subclasses, properties, domains, and ranges.
  """

  @section %Spark.Dsl.Section{
    name: :rdfs,
    describe: "Defines RDFS constructs like classes, subclasses, and property relationships.",
    sections: [
      AshRdf.Dsl.Sections.Rdfs.Class.build(),
      AshRdf.Dsl.Sections.Rdfs.PropertyDefinition.build()
    ],
    schema: [
      allow_inference: [
        type: :boolean,
        default: true,
        doc: "Whether to allow RDFS inference (subclass/subproperty relationships)"
      ]
    ]
  }
  
  @doc """
  Returns the RDFS DSL section.
  """
  def build, do: @section
end