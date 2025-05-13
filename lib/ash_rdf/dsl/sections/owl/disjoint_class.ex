defmodule AshRdf.Dsl.Sections.Owl.DisjointClass do
  @moduledoc """
  DSL section for defining disjoint class relationships in OWL.
  """

  @section %Spark.Dsl.Section{
    name: :disjoint_with,
    describe: "Defines a class disjointness relationship",
    schema: [
      class_uri: [
        type: :string,
        doc: "The URI of the disjoint class"
      ]
    ]
  }
  
  @doc """
  Returns the OWL disjoint class DSL section.
  """
  def build, do: @section
end