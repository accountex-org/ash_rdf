defmodule AshRdf.Dsl.Sections.Owl.Type do
  @moduledoc """
  DSL section for defining individual type assertions in OWL.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:type)
    desc("Defines a type assertion for an individual")
    
    option :class_uri, :string,
      doc: "The URI of the class that this individual belongs to"
  end
end