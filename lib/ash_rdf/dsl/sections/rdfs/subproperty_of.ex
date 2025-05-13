defmodule AshRdf.Dsl.Sections.Rdfs.SubpropertyOf do
  @moduledoc """
  DSL section for defining RDFS subproperty relationships.
  """

  @section %Spark.Dsl.Section{
    name: :subproperty_of,
    describe: "Defines a subproperty relationship",
    schema: [
      property_uri: [
        type: :string,
        doc: "The URI of the parent property"
      ]
    ]
  }
  
  @doc """
  Returns the RDFS subproperty relationship DSL section.
  """
  def build, do: @section
end