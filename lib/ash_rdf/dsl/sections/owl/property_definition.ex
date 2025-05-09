defmodule AshRdf.Dsl.Sections.Owl.PropertyDefinition do
  @moduledoc """
  DSL section for defining OWL properties.
  
  OWL2 extends RDFS property definitions with additional features
  for object properties and datatype properties.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:property)
    desc("Defines an OWL2 property")
    
    option :name, :atom,
      required: true,
      doc: "The name of the property"
      
    option :uri, :string,
      doc: "The URI for this property"
      
    option :type, {:one_of, [:object_property, :datatype_property, :annotation_property]},
      required: true,
      doc: "The type of OWL property"
      
    # Property relationships
    has_many :equivalent_to, AshRdf.Dsl.Sections.Owl.EquivalentProperty,
      default: [],
      doc: "Properties that this property is equivalent to"
      
    has_many :inverse_of, AshRdf.Dsl.Sections.Owl.InverseProperty,
      default: [],
      doc: "Properties that this property is the inverse of"
      
    # Property characteristics
    option :functional, :boolean,
      default: false,
      doc: "Whether this property is functional (has at most one value)"
      
    option :inverse_functional, :boolean,
      default: false,
      doc: "Whether this property is inverse functional"
      
    option :transitive, :boolean,
      default: false,
      doc: "Whether this property is transitive"
      
    option :symmetric, :boolean,
      default: false,
      doc: "Whether this property is symmetric"
      
    option :asymmetric, :boolean,
      default: false,
      doc: "Whether this property is asymmetric"
      
    option :reflexive, :boolean,
      default: false,
      doc: "Whether this property is reflexive"
      
    option :irreflexive, :boolean,
      default: false,
      doc: "Whether this property is irreflexive"
      
    # Annotations
    option :label, :string,
      doc: "Human-readable label for the property"
      
    option :comment, :string,
      doc: "Human-readable description of the property"
      
    # Deprecated feature
    option :deprecated, :boolean,
      default: false,
      doc: "Whether this property is deprecated"
  end
end