defmodule AshRdf.Dsl do
  @moduledoc """
  The DSL for AshRdf, providing constructs for working with RDF, RDFS, and OWL2.
  """

  @sections [
    AshRdf.Dsl.Sections.Rdf.build(),
    AshRdf.Dsl.Sections.Rdfs.build(),
    AshRdf.Dsl.Sections.Owl.build()
  ]

  use Spark.Dsl.Extension, sections: @sections

  def can_handle_extension?(module) do
    not is_nil(Spark.Dsl.Extension.get_opt(module, [:ash_rdf], :enable, nil))
  end
end