defmodule AshRdf.Dsl.Sections.Owl.EquivalentClass do
  @moduledoc """
  DSL section for defining equivalent class relationships in OWL.
  """

  @section %Spark.Dsl.Section{
    name: :equivalent_to,
    describe: "Defines a class equivalence relationship",
    schema: [
      class_uri: [
        type: :string,
        doc: "The URI of the equivalent class"
      ]
    ]
  }
  
  @doc """
  Returns the OWL equivalent class DSL section.
  """
  def build, do: @section
end