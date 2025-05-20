defmodule AshRdf.Dsl.Sections.Sparql do
  @moduledoc """
  DSL for configuring SPARQL data layer settings in an Ash resource.
  
  This module provides configuration options for connecting to SPARQL endpoints,
  mapping attributes to RDF properties, and optimizing queries.
  """

  @endpoint_schema [
    endpoint: [
      type: :string,
      required: true,
      doc: "The URL of the SPARQL endpoint"
    ],
    default_graph: [
      type: :string,
      doc: "The default graph URI to use for queries"
    ],
    update_endpoint: [
      type: :string,
      doc: "A separate endpoint for update operations (if different from the query endpoint)"
    ],
    credentials: [
      type: {:map, :any},
      doc: """
      Authentication credentials for the SPARQL endpoint.
      
      Supported formats:
      ```elixir
      %{
        auth_method: :basic,
        username: "username",
        password: "password"
      }
      ```
      
      ```elixir
      %{
        auth_method: :bearer,
        token: "token"
      }
      ```
      """
    ],
    client_options: [
      type: {:list, :any},
      default: [],
      doc: "Additional options to pass to the SPARQL client"
    ]
  ]

  @mapping_schema [
    attributes: [
      type: {:list, :any},
      default: [],
      doc: """
      Map Ash attributes to RDF predicates.
      
      Example:
      ```elixir
      attributes do
        map :name, to: "http://xmlns.com/foaf/0.1/name"
        map :email, to: "http://xmlns.com/foaf/0.1/mbox"
      end
      ```
      """
    ],
    class: [
      type: :string,
      doc: "The RDF class URI for this resource (overrides the one from rdfs section)"
    ],
    base_uri: [
      type: :string,
      doc: "The base URI for this resource (overrides the one from rdf section)"
    ]
  ]

  @options_schema [
    fetch_size: [
      type: :integer,
      default: 1000,
      doc: "Maximum number of results to fetch in a single query"
    ],
    timeout: [
      type: :integer,
      default: 30_000,
      doc: "Timeout for SPARQL queries in milliseconds"
    ],
    cache: [
      type: :boolean,
      default: false,
      doc: "Whether to cache query results"
    ],
    cache_ttl: [
      type: :integer,
      default: 60_000,
      doc: "Time-to-live for cached results in milliseconds"
    ],
    retry: [
      type: :boolean,
      default: true,
      doc: "Whether to retry failed queries"
    ],
    retry_count: [
      type: :integer,
      default: 3,
      doc: "Number of times to retry a failed query"
    ],
    retry_delay: [
      type: :integer,
      default: 1000,
      doc: "Delay between retries in milliseconds"
    ]
  ]

  @attribute_mapping_schema [
    map: [
      type: :atom,
      required: true,
      doc: "The Ash attribute to map"
    ],
    to: [
      type: :string,
      required: true,
      doc: "The RDF predicate URI to map to"
    ],
    datatype: [
      type: :string,
      doc: "The XSD datatype URI for the attribute"
    ],
    language: [
      type: :string,
      doc: "The language tag for string literals"
    ],
    inverse: [
      type: :boolean,
      default: false,
      doc: "Whether this is an inverse property mapping (object points to subject)"
    ]
  ]

  use Spark.Dsl.Section
  
  section do
    sections [:endpoint, :mapping, :options, :attributes]
    
    section :endpoint, schema: @endpoint_schema do
      identifier :name
    end
    
    section :mapping, schema: @mapping_schema do
      sections [:attributes]
      
      section :attributes do
        has_many :maps, schema: @attribute_mapping_schema
      end
    end
    
    section :options, schema: @options_schema do
    end
  end

  def info(resource) do
    # Get configuration sections
    endpoint = Spark.Dsl.Extension.get_opt(resource, [:sparql, :endpoint]) || %{}
    mapping = Spark.Dsl.Extension.get_opt(resource, [:sparql, :mapping]) || %{}
    options = Spark.Dsl.Extension.get_opt(resource, [:sparql, :options]) || %{}
    attribute_maps = get_attribute_maps(resource)
    
    # Build source configuration for data layer
    %{
      endpoint: Map.get(endpoint, :endpoint),
      default_graph: Map.get(endpoint, :default_graph),
      update_endpoint: Map.get(endpoint, :update_endpoint),
      credentials: Map.get(endpoint, :credentials),
      client_options: Map.get(endpoint, :client_options, []),
      class: Map.get(mapping, :class),
      base_uri: Map.get(mapping, :base_uri),
      fetch_size: Map.get(options, :fetch_size, 1000),
      timeout: Map.get(options, :timeout, 30_000),
      cache: Map.get(options, :cache, false),
      cache_ttl: Map.get(options, :cache_ttl, 60_000),
      retry: Map.get(options, :retry, true),
      retry_count: Map.get(options, :retry_count, 3),
      retry_delay: Map.get(options, :retry_delay, 1000),
      attribute_maps: attribute_maps
    }
  end

  # Get attribute mappings
  defp get_attribute_maps(resource) do
    mapping = Spark.Dsl.Extension.get_opt(resource, [:sparql, :mapping]) || %{}
    attributes_section = Map.get(mapping, :attributes, %{})
    maps = Map.get(attributes_section, :maps, [])
    
    maps
    |> Enum.map(fn map ->
      {Map.get(map, :map), %{
        uri: Map.get(map, :to),
        datatype: Map.get(map, :datatype),
        language: Map.get(map, :language),
        inverse: Map.get(map, :inverse, false)
      }}
    end)
    |> Enum.into(%{})
  end
end