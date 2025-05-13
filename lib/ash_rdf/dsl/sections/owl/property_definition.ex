defmodule AshRdf.Dsl.Sections.Owl.PropertyDefinition do
  @moduledoc """
  DSL section for defining OWL properties.
  
  OWL2 extends RDFS property definitions with additional features
  for object properties and datatype properties.
  """

  @section %Spark.Dsl.Section{
    name: :property,
    describe: "Defines an OWL2 property",
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the property"
      ],
      uri: [
        type: :string,
        doc: "The URI for this property"
      ],
      type: [
        type: {:one_of, [:object_property, :datatype_property, :annotation_property]},
        required: true,
        doc: "The type of OWL property"
      ],
      # Property characteristics
      functional: [
        type: :boolean,
        default: false,
        doc: "Whether this property is functional (has at most one value)"
      ],
      inverse_functional: [
        type: :boolean,
        default: false,
        doc: "Whether this property is inverse functional"
      ],
      transitive: [
        type: :boolean,
        default: false,
        doc: "Whether this property is transitive"
      ],
      symmetric: [
        type: :boolean,
        default: false,
        doc: "Whether this property is symmetric"
      ],
      asymmetric: [
        type: :boolean,
        default: false,
        doc: "Whether this property is asymmetric"
      ],
      reflexive: [
        type: :boolean,
        default: false,
        doc: "Whether this property is reflexive"
      ],
      irreflexive: [
        type: :boolean,
        default: false,
        doc: "Whether this property is irreflexive"
      ],
      # Annotations
      label: [
        type: :string,
        doc: "Human-readable label for the property"
      ],
      comment: [
        type: :string,
        doc: "Human-readable description of the property"
      ],
      # Deprecated feature
      deprecated: [
        type: :boolean,
        default: false,
        doc: "Whether this property is deprecated"
      ]
    ]
  }
  
  @doc """
  Returns the OWL property definition DSL section.
  """
  def build, do: @section
end