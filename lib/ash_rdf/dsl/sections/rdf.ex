defmodule AshRdf.Dsl.Sections.Rdf do
  @moduledoc """
  DSL section for core RDF (Resource Description Framework) concepts.
  
  This section defines the basic RDF constructs:
  - Resources (subjects)
  - Properties (predicates)
  - Values (objects)
  - Statements (triples)
  """

  @section %Spark.Dsl.Section{
    name: :rdf,
    describe: "Defines RDF resources, properties, and statements.",
    sections: [
      AshRdf.Dsl.Sections.Rdf.Resource.build(),
      AshRdf.Dsl.Sections.Rdf.Property.build(),
      AshRdf.Dsl.Sections.Rdf.Statement.build()
    ],
    schema: [
      base_uri: [
        type: :string,
        required: true,
        doc: "The base URI for all resources defined in this module"
      ],
      prefix: [
        type: :string,
        doc: "The preferred prefix for the base URI namespace"
      ],
      default_language: [
        type: :string,
        default: "en",
        doc: "The default language tag for literal values when not specified"
      ]
    ]
  }
  
  @doc """
  Returns the RDF DSL section.
  """
  def build, do: @section
end