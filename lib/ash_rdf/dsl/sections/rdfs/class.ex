defmodule AshRdf.Dsl.Sections.Rdfs.Class do
  @moduledoc """
  DSL section for defining RDFS classes.
  
  Classes in RDFS represent categories or types of resources.
  """

  @section %Spark.Dsl.Section{
    name: :class,
    describe: "Defines an RDFS class",
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the class"
      ],
      uri: [
        type: :string,
        doc: "The URI for this class (will be combined with base_uri if relative)"
      ],
      label: [
        type: :string,
        doc: "Human-readable label for the class"
      ],
      comment: [
        type: :string,
        doc: "Human-readable description of the class"
      ],
      see_also: [
        type: :string,
        doc: "Related resource to this class"
      ]
    ],
    sections: [
      AshRdf.Dsl.Sections.Rdfs.SubclassOf.build()
    ]
  }
  
  @doc """
  Returns the RDFS class DSL section.
  """
  def build, do: @section
end