defmodule AshRdf.Dsl.Sections.Owl do
  @moduledoc """
  DSL section for Web Ontology Language (OWL2) concepts.
  
  OWL2 extends RDFS with additional constructs for defining
  complex classes, properties, and constraints for advanced ontologies.
  """

  @section %Spark.Dsl.Section{
    name: :owl,
    describe: "Defines OWL2 ontology constructs.",
    sections: [
      AshRdf.Dsl.Sections.Owl.Ontology.build(),
      AshRdf.Dsl.Sections.Owl.ClassDefinition.build(),
      AshRdf.Dsl.Sections.Owl.PropertyDefinition.build(),
      AshRdf.Dsl.Sections.Owl.Individual.build(),
      AshRdf.Dsl.Sections.Owl.Restriction.build()
    ],
    schema: [
      profile: [
        type: {:one_of, [:rl, :el, :ql, :dl, :full]},
        default: :dl,
        doc: "The OWL2 profile to conform to"
      ],
      reasoning: [
        type: :boolean,
        default: true,
        doc: "Whether to enable OWL reasoning"
      ]
    ]
  }
  
  @doc """
  Returns the OWL DSL section.
  """
  def build, do: @section
end