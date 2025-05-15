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
  
  alias AshRdf.Sections.RdfSection
  alias AshRdf.Sections.RdfsSection
  alias AshRdf.Sections.OwlSection
  
  # Build the RDF section
  @rdf_section %Spark.Dsl.Section{
    name: :rdf,
    describe: "Define RDF resources, properties, and statements",
    schema: RdfSection.schema(),
    entities: RdfSection.entities(),
    imports: []
  }
  
  # Build the RDFS section
  @rdfs_section %Spark.Dsl.Section{
    name: :rdfs,
    describe: "Define RDFS classes, properties, and relationships",
    schema: RdfsSection.schema(),
    entities: RdfsSection.entities(),
    imports: []
  }
  
  # Build the OWL section
  @owl_section %Spark.Dsl.Section{
    name: :owl,
    describe: "Define OWL2 ontology constructs",
    schema: OwlSection.schema(),
    entities: OwlSection.entities(),
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