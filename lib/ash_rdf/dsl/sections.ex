defmodule AshRdf.Dsl.Sections do
  @moduledoc """
  Adds the sections to the AshRdf DSL.
  """
  
  @sections [
    %{
      name: :sparql,
      schema: AshRdf.Dsl.Sections.Sparql.dsl()
    }
  ]
  
  def sections, do: @sections
end