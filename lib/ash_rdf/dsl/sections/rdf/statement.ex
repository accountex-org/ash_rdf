defmodule AshRdf.Dsl.Sections.Rdf.Statement do
  @moduledoc """
  DSL section for defining RDF statements (triples).
  
  Statements in RDF are comprised of subject-predicate-object triples that
  form the basic data structure of the semantic web.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:statement)
    desc("Defines an RDF statement (triple)")
    
    option :subject, :string,
      required: true,
      doc: "The subject of the statement (resource identifier)"
      
    option :predicate, :string,
      required: true,
      doc: "The predicate of the statement (property identifier)"
      
    option :object, :any,
      required: true,
      doc: "The object of the statement (resource identifier or literal value)"
      
    option :language, :string,
      doc: "Language tag for literal values"
      
    option :datatype, :string,
      doc: "Datatype URI for literal values"
  end
end