defmodule AshRdf.Dsl.Sections.Owl.EquivalentClass do
  @moduledoc """
  DSL section for defining equivalent class relationships in OWL.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:equivalent_to)
    desc("Defines a class equivalence relationship")
    
    option :class_uri, :string,
      doc: "The URI of the equivalent class"
  end
end