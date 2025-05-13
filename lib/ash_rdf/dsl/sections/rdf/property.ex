defmodule AshRdf.Dsl.Sections.Rdf.Property do
  @moduledoc """
  DSL section for defining RDF properties (predicates).
  
  Properties in RDF are the predicates that connect subjects to objects,
  representing relationships between resources.
  """

  @section %Spark.Dsl.Section{
    name: :property,
    describe: "Defines an RDF property (predicate)",
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the property"
      ],
      uri: [
        type: :string,
        doc: "The URI for this property (will be combined with base_uri if relative)"
      ],
      domain: [
        type: :string,
        doc: "The domain (subject class) of this property"
      ],
      range: [
        type: :string,
        doc: "The range (object class) of this property"
      ],
      datatype: [
        type: :string,
        doc: "The datatype for literal values of this property"
      ]
    ]
  }
  
  @doc """
  Returns the RDF property DSL section.
  """
  def build, do: @section
end