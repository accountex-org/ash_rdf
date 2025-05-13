defmodule AshRdf.Dsl.Sections.Rdfs.PropertyDefinition do
  @moduledoc """
  DSL section for defining enhanced RDFS property definitions.
  
  RDFS extends RDF property definitions with additional metadata
  like domain, range, subproperty relationships, and documentation.
  """

  @section %Spark.Dsl.Section{
    name: :property,
    describe: "Defines an RDFS property with enhanced metadata",
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the property"
      ],
      uri: [
        type: :string,
        doc: "The URI for this property"
      ],
      domain: [
        type: :string,
        doc: "The domain (class) of this property"
      ],
      range: [
        type: :string,
        doc: "The range (class or datatype) of this property"
      ],
      label: [
        type: :string,
        doc: "Human-readable label for the property"
      ],
      comment: [
        type: :string,
        doc: "Human-readable description of the property"
      ]
    ],
    sections: [
      AshRdf.Dsl.Sections.Rdfs.SubpropertyOf.build()
    ]
  }
  
  @doc """
  Returns the RDFS property definition DSL section.
  """
  def build, do: @section
end