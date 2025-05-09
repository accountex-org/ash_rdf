defmodule AshRdf do
  @moduledoc """
  AshRdf is an extension for the Ash Framework that provides capabilities for working with
  RDF (Resource Description Framework) data and ontologies.

  This extension implements support for:
  - **RDF**: Core concepts of the Resource Description Framework including resources, 
    properties, literals, and statements (triples).
  - **RDFS (RDF Schema)**: Classes, subclasses, property definitions, domains, and ranges.
  - **OWL2 (Web Ontology Language)**: Complex class relationships, property characteristics, 
    individuals, and logical constraints.

  ## Basic Usage

  Enable the AshRdf extension in your Ash resource:

  ```elixir
  defmodule MyApp.People.Person do
    use Ash.Resource,
      extensions: [AshRdf]
      
    rdf do
      base_uri "http://example.org/people/"
      prefix "people"
    end
    
    # Define your resource attributes, relationships, etc.
  end
  ```

  ## Main Components

  ### RDF Core (`AshRdf.Rdf`)

  The RDF core provides functionality for creating and manipulating RDF triples 
  (subject-predicate-object statements) and graphs.

  ### RDFS (`AshRdf.Rdfs`)

  The RDFS module extends the basic RDF model with classes, property definitions,
  domains, ranges, and hierarchical relationships.

  ### OWL2 (`AshRdf.Owl`)

  The OWL2 module provides advanced ontology modeling capabilities with 
  sophisticated class expressions, property characteristics, and constraints.

  ## Serialization

  AshRdf supports serializing RDF data in multiple formats:
  - Turtle (`.ttl`): A concise, human-friendly format
  - N-Triples: A line-based, simple format
  - JSON-LD: RDF data represented in JSON

  ## Integration with Ash Resources

  AshRdf maps Ash resource definitions and data to RDF representations. This allows:
  - Exporting resource schema as RDFS/OWL ontologies
  - Converting resource instances to RDF data
  - Integrating Ash resources with the semantic web
  """

  use Spark.Dsl.Extension,
    transformers: [
      AshRdf.Transformers.ValidateRdfStructure
    ]

  @doc """
  Entrypoint for DSL-related functions.
  """
  defmacro __using__(opts \\ []) do
    quote do
      use Ash.Resource, opts: unquote(opts)
      use AshRdf.Dsl
    end
  end
end