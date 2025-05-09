defmodule AshRdf.Dsl.Sections.Owl.Ontology do
  @moduledoc """
  DSL section for defining OWL ontologies.
  
  An ontology in OWL2 is a collection of axioms that together
  describe a domain of interest.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:ontology)
    desc("Defines an OWL2 ontology")
    
    option :uri, :string,
      required: true,
      doc: "The URI for this ontology"
      
    option :version, :string,
      doc: "The version of this ontology"
      
    has_many :imports, AshRdf.Dsl.Sections.Owl.Import,
      default: [],
      doc: "Ontologies imported by this ontology"
      
    option :prefix, :string,
      doc: "The preferred prefix for this ontology"
      
    option :label, :string,
      doc: "Human-readable label for the ontology"
      
    option :comment, :string,
      doc: "Human-readable description of the ontology"
      
    option :prior_version, :string,
      doc: "URI of the prior version of this ontology"
      
    option :backward_compatible_with, :string,
      doc: "URI of a prior version that this version is compatible with"
      
    option :incompatible_with, :string,
      doc: "URI of a prior version that this version is incompatible with"
  end
end