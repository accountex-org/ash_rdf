defmodule AshRdf.Sections.OwlSection do
  @moduledoc """
  Defines the schema and entities for the `owl` section of the AshRdf DSL.
  
  OWL2 (Web Ontology Language) extends RDFS with additional constructs for defining:
  - Ontologies
  - Complex class expressions
  - Property characteristics
  - Restrictions
  - Individuals
  - Logical constraints
  """
  
  @doc """
  Returns the schema for the OWL section.
  """
  def schema do
    [
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
  end
  
  @doc """
  Returns the entity definitions for the OWL section.
  """
  def entities do
    [
      # Ontology entity
      %Spark.Dsl.Entity{
        name: :ontology,
        target: AshRdf.Entities.Ontology,
        describe: "Defines an OWL2 ontology",
        schema: [
          uri: [
            type: :string,
            doc: "The URI for this ontology"
          ],
          version: [
            type: :string,
            doc: "The version of the ontology"
          ],
          label: [
            type: :string,
            doc: "Human-readable label for the ontology"
          ],
          comment: [
            type: :string,
            doc: "Human-readable description of the ontology"
          ],
          imports: [
            type: {:list, :string},
            default: [],
            doc: "List of ontology URIs to import"
          ]
        ],
        entities: [import_entity()]
      },
      
      # Class definition entity
      %Spark.Dsl.Entity{
        name: :class_definition,
        target: AshRdf.Entities.ClassDefinition,
        describe: "Defines an OWL2 class",
        schema: [
          name: [
            type: :atom,
            required: true,
            doc: "The name of the class"
          ],
          uri: [
            type: :string,
            doc: "The URI for this class"
          ],
          label: [
            type: :string,
            doc: "Human-readable label for the class"
          ],
          comment: [
            type: :string,
            doc: "Human-readable description of the class"
          ],
          deprecated: [
            type: :boolean,
            default: false,
            doc: "Whether this class is deprecated"
          ]
        ],
        entities: [
          equivalent_class_entity(),
          disjoint_class_entity()
        ]
      },
      
      # Property definition entity
      %Spark.Dsl.Entity{
        name: :property_definition,
        target: AshRdf.Entities.PropertyDefinition,
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
            doc: "The type of property (object, datatype, or annotation)"
          ],
          domain: [
            type: {:or, [:string, :atom, {:list, {:or, [:string, :atom]}}]},
            doc: "The domain (subject type) of the property"
          ],
          range: [
            type: {:or, [:string, :atom, {:list, {:or, [:string, :atom]}}]},
            doc: "The range (object type) of the property"
          ],
          label: [
            type: :string,
            doc: "Human-readable label for the property"
          ],
          comment: [
            type: :string,
            doc: "Human-readable description of the property"
          ],
          functional: [
            type: :boolean,
            default: false,
            doc: "Whether this property is functional (at most one value per subject)"
          ],
          inverse_functional: [
            type: :boolean,
            default: false,
            doc: "Whether this property is inverse functional (at most one subject per value)"
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
          ]
        ]
      },
      
      # Individual entity
      %Spark.Dsl.Entity{
        name: :individual,
        target: AshRdf.Entities.Individual,
        describe: "Defines an OWL2 individual",
        schema: [
          name: [
            type: :atom,
            required: true,
            doc: "The name of the individual"
          ],
          uri: [
            type: :string,
            doc: "The URI for this individual"
          ],
          types: [
            type: {:list, {:or, [:string, :atom]}},
            default: [],
            doc: "The types (classes) of this individual"
          ],
          label: [
            type: :string,
            doc: "Human-readable label for the individual"
          ],
          comment: [
            type: :string,
            doc: "Human-readable description of the individual"
          ]
        ],
        entities: [property_assertion_entity()]
      },
      
      # Restriction entity
      %Spark.Dsl.Entity{
        name: :restriction,
        target: AshRdf.Entities.Restriction,
        describe: "Defines an OWL2 property restriction",
        schema: [
          name: [
            type: :atom,
            required: true,
            doc: "The name of the restriction"
          ],
          on_property: [
            type: {:or, [:string, :atom]},
            required: true,
            doc: "The property that this restriction applies to"
          ],
          some_values_from: [
            type: {:or, [:string, :atom]},
            doc: "Class where at least one value must come from (existential restriction)"
          ],
          all_values_from: [
            type: {:or, [:string, :atom]},
            doc: "Class where all values must come from (universal restriction)"
          ],
          value: [
            type: :any,
            doc: "Specific value that the property must have"
          ],
          min_cardinality: [
            type: :integer,
            doc: "Minimum number of values the property must have"
          ],
          max_cardinality: [
            type: :integer,
            doc: "Maximum number of values the property can have"
          ],
          cardinality: [
            type: :integer,
            doc: "Exact number of values the property must have"
          ],
          has_self: [
            type: :boolean,
            doc: "Whether the property relates individuals to themselves"
          ]
        ]
      },
      
      # Type declaration entity
      %Spark.Dsl.Entity{
        name: :type,
        target: AshRdf.Entities.Type,
        describe: "Declares a type (class) for a resource",
        schema: [
          class_uri: [
            type: {:or, [:string, :atom]},
            required: true,
            doc: "The URI or name of the class"
          ]
        ]
      }
    ]
  end
  
  # Helper function to define the import entity
  defp import_entity do
    %Spark.Dsl.Entity{
      name: :import,
      target: AshRdf.Entities.Import,
      describe: "Imports an external ontology",
      schema: [
        uri: [
          type: :string,
          required: true,
          doc: "The URI of the ontology to import"
        ]
      ]
    }
  end
  
  # Helper function to define the equivalent class entity
  defp equivalent_class_entity do
    %Spark.Dsl.Entity{
      name: :equivalent_class,
      target: AshRdf.Entities.EquivalentClass,
      describe: "Defines an equivalent class relationship",
      schema: [
        class_uri: [
          type: {:or, [:string, :atom]},
          required: true,
          doc: "The URI or name of the equivalent class"
        ]
      ]
    }
  end
  
  # Helper function to define the disjoint class entity
  defp disjoint_class_entity do
    %Spark.Dsl.Entity{
      name: :disjoint_class,
      target: AshRdf.Entities.DisjointClass,
      describe: "Defines a disjoint class relationship",
      schema: [
        class_uri: [
          type: {:or, [:string, :atom]},
          required: true,
          doc: "The URI or name of the disjoint class"
        ]
      ]
    }
  end
  
  # Helper function to define the property assertion entity
  defp property_assertion_entity do
    %Spark.Dsl.Entity{
      name: :property_assertion,
      target: AshRdf.Entities.PropertyAssertion,
      describe: "Asserts a property value for an individual",
      schema: [
        property: [
          type: {:or, [:string, :atom]},
          required: true,
          doc: "The property to assert"
        ],
        value: [
          type: :any,
          required: true,
          doc: "The value of the property"
        ],
        datatype: [
          type: :string,
          doc: "The XSD datatype for the value if it's a literal"
        ],
        language: [
          type: :string,
          doc: "The language tag for the value if it's a string literal"
        ]
      ]
    }
  end
end