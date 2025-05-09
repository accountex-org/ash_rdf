defmodule AshRdf.Dsl.Sections.Rdf.Property do
  @moduledoc """
  DSL section for defining RDF properties (predicates).
  
  Properties in RDF are the predicates that connect subjects to objects,
  representing relationships between resources.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:property)
    desc("Defines an RDF property (predicate)")
    
    option :name, :atom,
      required: true,
      doc: "The name of the property"
      
    option :uri, :string,
      doc: "The URI for this property (will be combined with base_uri if relative)"
      
    option :domain, :string,
      doc: "The domain (subject class) of this property"
      
    option :range, :string,
      doc: "The range (object class) of this property"
      
    option :datatype, :string,
      doc: "The datatype for literal values of this property"
  end
end