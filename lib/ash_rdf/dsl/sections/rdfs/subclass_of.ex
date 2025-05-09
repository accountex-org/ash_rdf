defmodule AshRdf.Dsl.Sections.Rdfs.SubclassOf do
  @moduledoc """
  DSL section for defining RDFS subclass relationships.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:subclass_of)
    desc("Defines a subclass relationship")
    
    option :class_uri, :string,
      doc: "The URI of the parent class"
  end
end