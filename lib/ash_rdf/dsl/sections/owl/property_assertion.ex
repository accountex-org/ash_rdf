defmodule AshRdf.Dsl.Sections.Owl.PropertyAssertion do
  @moduledoc """
  DSL section for defining property assertions for individuals in OWL.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:property_assertion)
    desc("Defines a property assertion for an individual")
    
    option :property, :string,
      required: true,
      doc: "The property URI or name"
      
    option :value, :any,
      required: true,
      doc: "The value of the property (individual URI or literal value)"
      
    option :datatype, :string,
      doc: "The datatype URI for literal values"
      
    option :language, :string,
      doc: "The language tag for literal values"
      
    option :negative, :boolean,
      default: false,
      doc: "Whether this is a negative property assertion"
  end
end