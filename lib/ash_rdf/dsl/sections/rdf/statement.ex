defmodule AshRdf.Dsl.Sections.Rdf.Statement do
  @moduledoc """
  DSL section for defining RDF statements (triples).
  
  Statements in RDF are comprised of subject-predicate-object triples that
  form the basic data structure of the semantic web.
  """

  @section %Spark.Dsl.Section{
    name: :statement,
    describe: "Defines an RDF statement (triple)",
    schema: [
      subject: [
        type: :string,
        required: true,
        doc: "The subject of the statement (resource identifier)"
      ],
      predicate: [
        type: :string,
        required: true,
        doc: "The predicate of the statement (property identifier)"
      ],
      object: [
        type: :any,
        required: true,
        doc: "The object of the statement (resource identifier or literal value)"
      ],
      language: [
        type: :string,
        doc: "Language tag for literal values"
      ],
      datatype: [
        type: :string,
        doc: "Datatype URI for literal values"
      ]
    ]
  }
  
  @doc """
  Returns the RDF statement DSL section.
  """
  def build, do: @section
end