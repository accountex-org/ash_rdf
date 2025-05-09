defmodule AshRdf.Dsl.Sections.Rdfs.PropertyDefinition do
  @moduledoc """
  DSL section for defining enhanced RDFS property definitions.
  
  RDFS extends RDF property definitions with additional metadata
  like domain, range, subproperty relationships, and documentation.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:property)
    desc("Defines an RDFS property with enhanced metadata")
    
    option :name, :atom,
      required: true,
      doc: "The name of the property"
      
    option :uri, :string,
      doc: "The URI for this property"
      
    option :domain, :string,
      doc: "The domain (class) of this property"
      
    option :range, :string,
      doc: "The range (class or datatype) of this property"
      
    has_many :subproperty_of, AshRdf.Dsl.Sections.Rdfs.SubpropertyOf,
      default: [],
      doc: "Properties that this property is a subproperty of"
      
    option :label, :string,
      doc: "Human-readable label for the property"
      
    option :comment, :string,
      doc: "Human-readable description of the property"
  end
end