defmodule AshRdf.Dsl.Sections.Rdfs.SubpropertyOf do
  @moduledoc """
  DSL section for defining RDFS subproperty relationships.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:subproperty_of)
    desc("Defines a subproperty relationship")
    
    option :property_uri, :string,
      doc: "The URI of the parent property"
  end
end