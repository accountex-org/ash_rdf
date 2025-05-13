defmodule AshRdf.Dsl.Sections.Owl.Restriction do
  @moduledoc """
  DSL section for defining OWL property restrictions.
  
  Restrictions in OWL2 create anonymous classes based on conditions
  on properties.
  """

  @section %Spark.Dsl.Section{
    name: :restriction,
    describe: "Defines an OWL2 property restriction",
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the restriction (for reference in the DSL)"
      ],
      on_property: [
        type: :string,
        required: true,
        doc: "The property that this restriction applies to"
      ],
      # Cardinality restrictions
      min_cardinality: [
        type: :integer,
        doc: "The minimum cardinality of the property"
      ],
      max_cardinality: [
        type: :integer,
        doc: "The maximum cardinality of the property"
      ],
      exact_cardinality: [
        type: :integer,
        doc: "The exact cardinality of the property"
      ],
      # Qualified cardinality restrictions
      min_qualified_cardinality: [
        type: :integer,
        doc: "The minimum qualified cardinality of the property"
      ],
      max_qualified_cardinality: [
        type: :integer,
        doc: "The maximum qualified cardinality of the property"
      ],
      exact_qualified_cardinality: [
        type: :integer,
        doc: "The exact qualified cardinality of the property"
      ],
      qualified_on_class: [
        type: :string,
        doc: "The class that qualifies the cardinality restriction"
      ],
      # Value restrictions
      some_values_from: [
        type: :string,
        doc: "Class for existential restriction (some values from)"
      ],
      all_values_from: [
        type: :string,
        doc: "Class for universal restriction (all values from)"
      ],
      has_value: [
        type: :any,
        doc: "Value for hasValue restriction"
      ],
      has_self: [
        type: :boolean,
        doc: "Whether this restriction is a self-restriction"
      ]
    ]
  }
  
  @doc """
  Returns the OWL restriction DSL section.
  """
  def build, do: @section
end