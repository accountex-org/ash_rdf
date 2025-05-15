defmodule AshRdf.Dsl do
  @moduledoc """
  The DSL for AshRdf, providing constructs for working with RDF, RDFS, and OWL2.
  
  This module defines the structure of the AshRdf DSL extension for the Ash framework.
  It organizes the sections for RDF, RDFS, and OWL into a cohesive structure that
  can be used in Ash resources.
  
  ## Usage
  
  ```elixir
  defmodule MyApp.People.Person do
    use Ash.Resource,
      extensions: [AshRdf.Dsl]
      
    ash_rdf do
      rdf do
        base_uri "http://example.org/people/"
        prefix "people"
      end
      
      rdfs do
        class name: :person do
          label "Person"
          comment "A human being"
        end
      end
      
      owl do
        ontology do
          uri "http://example.org/ontology/"
          version "1.0.0"
        end
      end
    end
    
    # Define your resource attributes, relationships, etc.
  end
  ```
  """
  
  require Logger
  
  # Define entity modules
  @identifier_entity %Spark.Dsl.Entity{
    name: :identifier,
    target: AshRdf.Entities.Identifier,
    describe: "Identifies a resource or property",
    schema: [
      name: [
        type: :string,
        required: true,
        doc: "The identifier for the resource or property"
      ]
    ]
  }
  
  @resource_entity %Spark.Dsl.Entity{
    name: :resource,
    target: AshRdf.Entities.Resource,
    describe: "Defines an RDF resource (subject)",
    schema: [
      uri: [
        type: :string,
        doc: "The URI for this resource (will be combined with base_uri if relative)"
      ],
      blank_node: [
        type: :boolean,
        default: false,
        doc: "Whether this resource is a blank node"
      ],
      blank_node_id: [
        type: :string,
        doc: "Optional identifier for blank nodes"
      ]
    ],
    imports: [@identifier_entity]
  }
  
  @property_entity %Spark.Dsl.Entity{
    name: :property,
    target: AshRdf.Entities.Property,
    describe: "Defines an RDF property (predicate)",
    schema: [
      uri: [
        type: :string,
        doc: "The URI for this property (will be combined with base_uri if relative)"
      ],
      datatype: [
        type: :string,
        doc: "The XSD datatype for the property values"
      ]
    ],
    imports: [@identifier_entity]
  }
  
  @statement_entity %Spark.Dsl.Entity{
    name: :statement,
    target: AshRdf.Entities.Statement,
    describe: "Defines an RDF statement (triple)",
    schema: [
      subject: [
        type: :string,
        required: true,
        doc: "The subject of the statement (resource URI or identifier)"
      ],
      predicate: [
        type: :string,
        required: true,
        doc: "The predicate of the statement (property URI or identifier)"
      ],
      object: [
        type: {:or, [:string, :atom, :integer, :float, :boolean]},
        required: true,
        doc: "The object of the statement (resource URI, identifier, or literal value)"
      ],
      datatype: [
        type: :string,
        doc: "The XSD datatype for the object if it's a literal"
      ],
      language: [
        type: :string,
        doc: "The language tag for the object if it's a string literal"
      ]
    ]
  }
  
  @subclass_of_entity %Spark.Dsl.Entity{
    name: :subclass_of,
    target: AshRdf.Entities.SubclassOf,
    describe: "Defines a subclass relationship",
    schema: [
      class_uri: [
        type: {:or, [:string, :atom]},
        required: true,
        doc: "The URI or name of the superclass"
      ]
    ]
  }
  
  @class_entity %Spark.Dsl.Entity{
    name: :class,
    target: AshRdf.Entities.Class,
    describe: "Defines an RDFS class",
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the class"
      ],
      uri: [
        type: :string,
        doc: "The URI for this class (will be combined with base_uri if relative)"
      ],
      label: [
        type: :string,
        doc: "Human-readable label for the class"
      ],
      comment: [
        type: :string,
        doc: "Human-readable description of the class"
      ]
    ],
    imports: [@subclass_of_entity]
  }
  
  @subproperty_of_entity %Spark.Dsl.Entity{
    name: :subproperty_of,
    target: AshRdf.Entities.SubpropertyOf,
    describe: "Defines a subproperty relationship",
    schema: [
      property_uri: [
        type: {:or, [:string, :atom]},
        required: true,
        doc: "The URI or name of the superproperty"
      ]
    ]
  }
  
  @property_definition_entity %Spark.Dsl.Entity{
    name: :property_definition,
    target: AshRdf.Entities.PropertyDefinition,
    describe: "Defines an RDFS property",
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the property"
      ],
      uri: [
        type: :string,
        doc: "The URI for this property (will be combined with base_uri if relative)"
      ],
      domain: [
        type: {:or, [:string, :atom]},
        doc: "The domain (subject type) of the property"
      ],
      range: [
        type: {:or, [:string, :atom]},
        doc: "The range (object type) of the property"
      ],
      label: [
        type: :string,
        doc: "Human-readable label for the property"
      ],
      comment: [
        type: :string,
        doc: "Human-readable description of the property"
      ]
    ],
    imports: [@subproperty_of_entity]
  }
  
  @import_entity %Spark.Dsl.Entity{
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
  
  @ontology_entity %Spark.Dsl.Entity{
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
    imports: [@import_entity]
  }
  
  @equivalent_class_entity %Spark.Dsl.Entity{
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
  
  @disjoint_class_entity %Spark.Dsl.Entity{
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
  
  @class_definition_entity %Spark.Dsl.Entity{
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
    imports: [
      @equivalent_class_entity,
      @disjoint_class_entity
    ]
  }
  
  @property_assertion_entity %Spark.Dsl.Entity{
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
  
  @individual_entity %Spark.Dsl.Entity{
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
    imports: [@property_assertion_entity]
  }
  
  @restriction_entity %Spark.Dsl.Entity{
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
  }
  
  @type_entity %Spark.Dsl.Entity{
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
  
  # Build the RDF section
  @rdf_section %Spark.Dsl.Section{
    name: :rdf,
    describe: "Define RDF resources, properties, and statements",
    schema: [
      base_uri: [
        type: :string,
        required: true,
        doc: "The base URI for all resources defined in this module"
      ],
      prefix: [
        type: :string,
        doc: "The preferred prefix for the base URI namespace"
      ],
      default_language: [
        type: :string,
        default: "en",
        doc: "The default language tag for literal values when not specified"
      ]
    ],
    entities: [
      @resource_entity,
      @property_entity,
      @statement_entity
    ],
    imports: []
  }
  
  # Build the RDFS section
  @rdfs_section %Spark.Dsl.Section{
    name: :rdfs,
    describe: "Define RDFS classes, properties, and relationships",
    schema: [
      allow_inference: [
        type: :boolean,
        default: true,
        doc: "Whether to allow RDFS inference (subclass/subproperty relationships)"
      ]
    ],
    entities: [
      @class_entity,
      @property_definition_entity
    ],
    imports: []
  }
  
  # Build the OWL section
  @owl_section %Spark.Dsl.Section{
    name: :owl,
    describe: "Define OWL2 ontology constructs",
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
    ],
    entities: [
      @ontology_entity,
      @class_definition_entity,
      @property_definition_entity,
      @individual_entity,
      @restriction_entity,
      @type_entity
    ],
    imports: []
  }
  
  # Top-level section that contains all other sections
  @ash_rdf_section %Spark.Dsl.Section{
    name: :ash_rdf,
    describe: "Configure RDF, RDFS, and OWL capabilities for Ash resources",
    sections: [
      @rdf_section,
      @rdfs_section,
      @owl_section
    ]
  }
  
  # The main extension
  use Spark.Dsl.Extension,
    sections: [@ash_rdf_section],
    transformers: [
      AshRdf.Transformers.ValidateRdfStructure
    ],
    verifiers: [
      AshRdf.Verifiers.ValidateUri
    ]
  
  @doc """
  Determine if a resource uses the `ash_rdf` extension.
  
  ## Examples
  
      iex> AshRdf.Dsl.extension?(SomeResource)
      true
      
      iex> AshRdf.Dsl.extension?(OtherResource)
      false
  """
  @spec extension?(Ash.Resource.t()) :: boolean()
  def extension?(resource) do
    extensions = Spark.extensions(resource)
    __MODULE__ in extensions
  end
  
  @doc """
  Return the section definitions for use in custom DSL extensions.
  
  This is used in tests to create custom DSL extensions without verifiers.
  """
  @spec __sections__() :: Spark.Dsl.Section.t()
  def __sections__() do
    @ash_rdf_section
  end
end