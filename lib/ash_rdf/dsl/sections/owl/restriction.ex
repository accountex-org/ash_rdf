defmodule AshRdf.Dsl.Sections.Owl.Restriction do
  @moduledoc """
  DSL section for defining OWL property restrictions.
  
  Restrictions in OWL2 create anonymous classes based on conditions
  on properties.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:restriction)
    desc("Defines an OWL2 property restriction")
    
    option :name, :atom,
      required: true,
      doc: "The name of the restriction (for reference in the DSL)"
      
    option :on_property, :string,
      required: true,
      doc: "The property that this restriction applies to"
      
    # Cardinality restrictions
    option :min_cardinality, :integer,
      doc: "The minimum cardinality of the property"
      
    option :max_cardinality, :integer,
      doc: "The maximum cardinality of the property"
      
    option :exact_cardinality, :integer,
      doc: "The exact cardinality of the property"
      
    # Qualified cardinality restrictions
    option :min_qualified_cardinality, :integer,
      doc: "The minimum qualified cardinality of the property"
      
    option :max_qualified_cardinality, :integer,
      doc: "The maximum qualified cardinality of the property"
      
    option :exact_qualified_cardinality, :integer,
      doc: "The exact qualified cardinality of the property"
      
    option :qualified_on_class, :string,
      doc: "The class that qualifies the cardinality restriction"
      
    # Value restrictions
    option :some_values_from, :string,
      doc: "Class for existential restriction (some values from)"
      
    option :all_values_from, :string,
      doc: "Class for universal restriction (all values from)"
      
    option :has_value, :any,
      doc: "Value for hasValue restriction"
      
    option :has_self, :boolean,
      doc: "Whether this restriction is a self-restriction"
  end
end