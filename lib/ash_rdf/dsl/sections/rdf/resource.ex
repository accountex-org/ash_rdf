defmodule AshRdf.Dsl.Sections.Rdf.Resource do
  @moduledoc """
  DSL section for defining RDF resources (subjects).
  
  Resources in RDF are identified by URIs and represent the entities described.
  """

  @section %Spark.Dsl.Section{
    name: :resource,
    describe: "Defines an RDF resource",
    schema: [
      uri: [
        type: :string,
        doc: "The URI for this resource (will be combined with base_uri if relative)"
      ],
      blank_node: [
        type: :boolean,
        default: false,
        doc: "Whether this resource is a blank node"
      ],
      blank_node_id: [
        type: :string,
        doc: "Optional identifier for blank nodes"
      ]
    ],
    sections: [
      AshRdf.Dsl.Sections.Rdf.Identifier.build()
    ]
  }
  
  @doc """
  Returns the RDF resource DSL section.
  """
  def build, do: @section
end