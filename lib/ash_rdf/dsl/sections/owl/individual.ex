defmodule AshRdf.Dsl.Sections.Owl.Individual do
  @moduledoc """
  DSL section for defining OWL individuals.
  
  Individuals in OWL2 are instances of classes.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:individual)
    desc("Defines an OWL2 individual")
    
    option :name, :atom,
      required: true,
      doc: "The name of the individual"
      
    option :uri, :string,
      doc: "The URI for this individual"
      
    # Class membership
    has_many :types, AshRdf.Dsl.Sections.Owl.Type,
      default: [],
      doc: "Classes that this individual is a member of"
      
    # Individual relationships
    has_many :same_as, AshRdf.Dsl.Sections.Owl.SameIndividual,
      default: [],
      doc: "Individuals that this individual is the same as"
      
    has_many :different_from, AshRdf.Dsl.Sections.Owl.DifferentIndividual,
      default: [],
      doc: "Individuals that this individual is different from"
      
    # Property assertions
    has_many :property_assertions, AshRdf.Dsl.Sections.Owl.PropertyAssertion,
      default: [],
      doc: "Property assertions for this individual"
      
    # Annotations
    option :label, :string,
      doc: "Human-readable label for the individual"
      
    option :comment, :string,
      doc: "Human-readable description of the individual"
  end
end