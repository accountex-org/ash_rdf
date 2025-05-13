defmodule AshRdf.Dsl.Sections.Owl.Type do
  @moduledoc """
  DSL section for defining individual type assertions in OWL.
  """

  @section %Spark.Dsl.Section{
    name: :type,
    describe: "Defines a type assertion for an individual",
    schema: [
      class_uri: [
        type: :string,
        doc: "The URI of the class that this individual belongs to"
      ]
    ]
  }
  
  @doc """
  Returns the OWL type assertion DSL section.
  """
  def build, do: @section
end