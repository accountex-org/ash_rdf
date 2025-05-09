defmodule AshRdf.Dsl do
  @moduledoc """
  The DSL for AshRdf, providing constructs for working with RDF, RDFS, and OWL2.
  """

  @sections [
    AshRdf.Dsl.Sections.Rdf,
    AshRdf.Dsl.Sections.Rdfs,
    AshRdf.Dsl.Sections.Owl
  ]

  use Spark.Dsl.Extension, sections: @sections

  def can_handle_extension?(module) do
    not is_nil(Spark.Dsl.Extension.get_opt(module, [:ash_rdf], :enable, nil))
  end
end