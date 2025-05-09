defmodule AshRdf.Dsl.Sections.Owl.Import do
  @moduledoc """
  DSL section for defining ontology imports in OWL.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:import)
    desc("Defines an ontology import relationship")
    
    option :uri, :string,
      required: true,
      doc: "The URI of the imported ontology"
  end
end