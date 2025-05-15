defmodule AshRdf.Sections.RdfSection do
  @moduledoc """
  DSL section for core RDF (Resource Description Framework) concepts.
  
  This section defines the basic RDF constructs:
  - Resources (subjects)
  - Properties (predicates)
  - Values (objects)
  - Statements (triples)
  """
  
  @doc """
  Returns the schema for the RDF section.
  """
  def schema do
    [
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
    ]
  end
  
  @doc """
  Returns the entity definitions for the RDF section.
  """
  def entities do
    [
      # Resource entity
      %Spark.Dsl.Entity{
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
        entities: [identifier_entity()]
      },
      
      # Property entity
      %Spark.Dsl.Entity{
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
        entities: [identifier_entity()]
      },
      
      # Statement entity
      %Spark.Dsl.Entity{
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
    ]
  end
  
  # Helper function to define the identifier entity
  defp identifier_entity do
    %Spark.Dsl.Entity{
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
  end
end