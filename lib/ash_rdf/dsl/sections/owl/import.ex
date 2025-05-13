defmodule AshRdf.Dsl.Sections.Owl.Import do
  @moduledoc """
  DSL section for defining ontology imports in OWL.
  """

  @section %Spark.Dsl.Section{
    name: :import,
    describe: "Defines an ontology import relationship",
    schema: [
      uri: [
        type: :string,
        required: true,
        doc: "The URI of the imported ontology"
      ]
    ]
  }
  
  @doc """
  Returns the OWL import DSL section.
  """
  def build, do: @section
end