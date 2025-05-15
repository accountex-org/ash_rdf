defmodule AshRdf.Owl.Ontology do
  @moduledoc """
  Functions for working with OWL ontologies.
  """
  
  alias Spark.Dsl.Extension
  alias AshRdf.Rdf.Statement
  
  @owl_namespace "http://www.w3.org/2002/07/owl#"
  @rdf_namespace "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  @dc_namespace "http://purl.org/dc/elements/1.1/"
  
  @doc """
  Gets all OWL ontologies defined in a resource.
  """
  def ontologies(resource) do
    Extension.get_entities(resource, [:owl, :ontology])
  end
  
  @doc """
  Gets the main OWL ontology defined in a resource.
  """
  def main_ontology(resource) do
    # Simply returns the first ontology defined, if any
    case ontologies(resource) do
      [first | _] -> first
      _ -> nil
    end
  end
  
  @doc """
  Gets the URI for an OWL ontology.
  """
  def ontology_uri(_resource, ontology_entity) do
    ontology_entity.uri
  end
  
  @doc """
  Converts OWL ontology definitions to RDF statements.
  """
  def to_rdf(resource) do
    # Generate statements for each ontology
    Enum.flat_map(ontologies(resource), fn ontology_entity ->
      ontology_uri = ontology_uri(resource, ontology_entity)
      
      # Ontology type statement
      type_statement = Statement.new(
        ontology_uri,
        "#{@rdf_namespace}type",
        "#{@owl_namespace}Ontology"
      )
      
      # Version statement if present
      version_statements = if ontology_entity.version do
        [Statement.new(ontology_uri, "#{@owl_namespace}versionInfo", ontology_entity.version)]
      else
        []
      end
      
      # Label statement if present
      label_statements = if ontology_entity.label do
        [Statement.new(ontology_uri, "#{@dc_namespace}title", ontology_entity.label)]
      else
        []
      end
      
      # Comment statement if present
      comment_statements = if ontology_entity.comment do
        [Statement.new(ontology_uri, "#{@dc_namespace}description", ontology_entity.comment)]
      else
        []
      end
      
      # Import statements
      import_statements = Enum.map(ontology_entity.imports, fn import_entity ->
        import_uri = import_entity.uri
        Statement.new(ontology_uri, "#{@owl_namespace}imports", import_uri)
      end)
      
      # Prior version statement if present
      prior_version_statements = if ontology_entity.prior_version do
        [Statement.new(ontology_uri, "#{@owl_namespace}priorVersion", ontology_entity.prior_version)]
      else
        []
      end
      
      # Backward compatibility statement if present
      backward_compatible_statements = if ontology_entity.backward_compatible_with do
        [Statement.new(ontology_uri, "#{@owl_namespace}backwardCompatibleWith", ontology_entity.backward_compatible_with)]
      else
        []
      end
      
      # Incompatibility statement if present
      incompatible_statements = if ontology_entity.incompatible_with do
        [Statement.new(ontology_uri, "#{@owl_namespace}incompatibleWith", ontology_entity.incompatible_with)]
      else
        []
      end
      
      # Combine all statements
      [type_statement] ++ version_statements ++ label_statements ++ comment_statements ++
        import_statements ++ prior_version_statements ++ backward_compatible_statements ++
        incompatible_statements
    end)
  end
end