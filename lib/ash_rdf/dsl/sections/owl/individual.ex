defmodule AshRdf.Dsl.Sections.Owl.Individual do
  @moduledoc """
  DSL section for defining OWL individuals.
  
  Individuals in OWL2 are instances of classes.
  """

  @section %Spark.Dsl.Section{
    name: :individual,
    describe: "Defines an OWL2 individual",
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the individual"
      ],
      uri: [
        type: :string,
        doc: "The URI for this individual"
      ],
      label: [
        type: :string,
        doc: "Human-readable label for the individual"
      ],
      comment: [
        type: :string,
        doc: "Human-readable description of the individual"
      ]
    ],
    sections: [
      AshRdf.Dsl.Sections.Owl.Type.build(),
      AshRdf.Dsl.Sections.Owl.PropertyAssertion.build()
    ]
  }
  
  @doc """
  Returns the OWL individual DSL section.
  """
  def build, do: @section
end