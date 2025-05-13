defmodule AshRdf.Dsl.Sections.Rdfs.SubclassOf do
  @moduledoc """
  DSL section for defining RDFS subclass relationships.
  """

  @section %Spark.Dsl.Section{
    name: :subclass_of,
    describe: "Defines a subclass relationship",
    schema: [
      class_uri: [
        type: :string,
        doc: "The URI of the parent class"
      ]
    ]
  }
  
  @doc """
  Returns the RDFS subclass relationship DSL section.
  """
  def build, do: @section
end