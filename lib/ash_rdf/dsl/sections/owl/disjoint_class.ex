defmodule AshRdf.Dsl.Sections.Owl.DisjointClass do
  @moduledoc """
  DSL section for defining disjoint class relationships in OWL.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:disjoint_with)
    desc("Defines a class disjointness relationship")
    
    option :class_uri, :string,
      doc: "The URI of the disjoint class"
  end
end