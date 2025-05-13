defmodule AshRdf.Dsl.Sections.Owl.ClassDefinition do
  @moduledoc """
  DSL section for defining OWL classes.
  
  OWL2 classes extend RDFS classes with more complex relationships
  and constraints.
  """

  @section %Spark.Dsl.Section{
    name: :class,
    describe: "Defines an OWL2 class",
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the class"
      ],
      uri: [
        type: :string,
        doc: "The URI for this class"
      ],
      label: [
        type: :string,
        doc: "Human-readable label for the class"
      ],
      comment: [
        type: :string,
        doc: "Human-readable description of the class"
      ],
      deprecated: [
        type: :boolean,
        default: false,
        doc: "Whether this class is deprecated"
      ]
    ],
    sections: [
      AshRdf.Dsl.Sections.Owl.EquivalentClass.build(),
      AshRdf.Dsl.Sections.Owl.DisjointClass.build()
    ]
  }
  
  @doc """
  Returns the OWL class definition DSL section.
  """
  def build, do: @section
end