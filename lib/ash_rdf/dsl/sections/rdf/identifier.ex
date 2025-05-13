defmodule AshRdf.Dsl.Sections.Rdf.Identifier do
  @moduledoc """
  DSL section for defining RDF resource identifiers.
  
  Resources in RDF can have various identifiers including URIs and blank node IDs.
  """

  @section %Spark.Dsl.Section{
    name: :identifier,
    describe: "Defines an identifier for an RDF resource",
    schema: [
      uri: [
        type: :string,
        doc: "The URI for this resource identifier"
      ],
      blank_node_id: [
        type: :string,
        doc: "The blank node identifier"
      ]
    ]
  }
  
  @doc """
  Returns the RDF identifier DSL section.
  """
  def build, do: @section
end