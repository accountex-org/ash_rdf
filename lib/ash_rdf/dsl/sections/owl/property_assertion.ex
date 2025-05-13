defmodule AshRdf.Dsl.Sections.Owl.PropertyAssertion do
  @moduledoc """
  DSL section for defining property assertions for individuals in OWL.
  """

  @section %Spark.Dsl.Section{
    name: :property_assertion,
    describe: "Defines a property assertion for an individual",
    schema: [
      property: [
        type: :string,
        required: true,
        doc: "The property URI or name"
      ],
      value: [
        type: :any,
        required: true,
        doc: "The value of the property (individual URI or literal value)"
      ],
      datatype: [
        type: :string,
        doc: "The datatype URI for literal values"
      ],
      language: [
        type: :string,
        doc: "The language tag for literal values"
      ],
      negative: [
        type: :boolean,
        default: false,
        doc: "Whether this is a negative property assertion"
      ]
    ]
  }
  
  @doc """
  Returns the OWL property assertion DSL section.
  """
  def build, do: @section
end