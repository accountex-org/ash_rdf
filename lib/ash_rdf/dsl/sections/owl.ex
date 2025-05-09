defmodule AshRdf.Dsl.Sections.Owl do
  @moduledoc """
  DSL section for Web Ontology Language (OWL2) concepts.
  
  OWL2 extends RDFS with additional constructs for defining
  complex classes, properties, and constraints for advanced ontologies.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:owl)
    desc("Defines OWL2 ontology constructs.")

    sections([
      AshRdf.Dsl.Sections.Owl.Ontology,
      AshRdf.Dsl.Sections.Owl.ClassDefinition,
      AshRdf.Dsl.Sections.Owl.PropertyDefinition,
      AshRdf.Dsl.Sections.Owl.Individual,
      AshRdf.Dsl.Sections.Owl.Restriction
    ])
    
    # OWL options
    option :profile, {:one_of, [:rl, :el, :ql, :dl, :full]}, 
      default: :dl,
      doc: "The OWL2 profile to conform to"
      
    option :reasoning, :boolean,
      default: true,
      doc: "Whether to enable OWL reasoning"
  end
end