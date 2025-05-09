defmodule AshRdf.Dsl.Sections.Owl.ClassDefinition do
  @moduledoc """
  DSL section for defining OWL classes.
  
  OWL2 classes extend RDFS classes with more complex relationships
  and constraints.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:class)
    desc("Defines an OWL2 class")
    
    option :name, :atom,
      required: true,
      doc: "The name of the class"
      
    option :uri, :string,
      doc: "The URI for this class"
      
    # Class relationships
    has_many :equivalent_to, AshRdf.Dsl.Sections.Owl.EquivalentClass,
      default: [],
      doc: "Classes that this class is equivalent to"
      
    has_many :disjoint_with, AshRdf.Dsl.Sections.Owl.DisjointClass,
      default: [],
      doc: "Classes that this class is disjoint with"
      
    # Class expressions
    has_many :intersection_of, AshRdf.Dsl.Sections.Owl.IntersectionOf,
      default: [],
      doc: "Classes that this class is the intersection of"
      
    has_many :union_of, AshRdf.Dsl.Sections.Owl.UnionOf,
      default: [],
      doc: "Classes that this class is the union of"
      
    has_many :complement_of, AshRdf.Dsl.Sections.Owl.ComplementOf,
      default: [],
      doc: "Classes that this class is the complement of"
      
    # Annotations
    option :label, :string,
      doc: "Human-readable label for the class"
      
    option :comment, :string,
      doc: "Human-readable description of the class"
      
    # Deprecated feature
    option :deprecated, :boolean,
      default: false,
      doc: "Whether this class is deprecated"
  end
end