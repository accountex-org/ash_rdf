defmodule AshRdf.Sections.RdfsSection do
  @moduledoc """
  Defines the schema and entities for the `rdfs` section of the AshRdf DSL.
  
  RDFS (RDF Schema) extends RDF with additional vocabulary for describing:
  - Classes
  - Subclasses
  - Properties with domains and ranges
  - Hierarchical relationships
  """
  
  @doc """
  Returns the schema for the RDFS section.
  """
  def schema do
    [
      allow_inference: [
        type: :boolean,
        default: true,
        doc: "Whether to allow RDFS inference (subclass/subproperty relationships)"
      ]
    ]
  end
  
  @doc """
  Returns the entity definitions for the RDFS section.
  """
  def entities do
    [
      # Class entity
      %Spark.Dsl.Entity{
        name: :class,
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
        entities: [subclass_of_entity()]
      },
      
      # Property definition entity
      %Spark.Dsl.Entity{
        name: :property_definition,
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
        entities: [subproperty_of_entity()]
      }
    ]
  end
  
  # Helper function to define the subclass_of entity
  defp subclass_of_entity do
    %Spark.Dsl.Entity{
      name: :subclass_of,
      describe: "Defines a subclass relationship",
      schema: [
        class_uri: [
          type: {:or, [:string, :atom]},
          required: true,
          doc: "The URI or name of the superclass"
        ]
      ]
    }
  end
  
  # Helper function to define the subproperty_of entity
  defp subproperty_of_entity do
    %Spark.Dsl.Entity{
      name: :subproperty_of,
      describe: "Defines a subproperty relationship",
      schema: [
        property_uri: [
          type: {:or, [:string, :atom]},
          required: true,
          doc: "The URI or name of the superproperty"
        ]
      ]
    }
  end
end