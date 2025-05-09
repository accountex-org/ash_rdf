defmodule AshRdf.Owl.Individual do
  @moduledoc """
  Functions for working with OWL individuals.
  """
  
  alias Spark.Dsl.Extension
  alias AshRdf.Rdf.{Statement, Uri}
  
  @owl_namespace "http://www.w3.org/2002/07/owl#"
  @rdf_namespace "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  @rdfs_namespace "http://www.w3.org/2000/01/rdf-schema#"
  
  @doc """
  Gets all OWL individuals defined in a resource.
  """
  def individuals(resource) do
    Extension.get_entities(resource, [:owl, :individual])
  end
  
  @doc """
  Gets a specific OWL individual from a resource by name.
  """
  def individual_by_name(resource, name) do
    individuals(resource)
    |> Enum.find(&(&1.name == name))
  end
  
  @doc """
  Gets the URI for an OWL individual.
  """
  def individual_uri(resource, individual_entity) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    Uri.resolve(individual_entity.uri || to_string(individual_entity.name), base_uri)
  end
  
  @doc """
  Converts OWL individual definitions to RDF statements.
  """
  def to_rdf(resource) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    
    # Generate statements for each individual
    Enum.flat_map(individuals(resource), fn individual_entity ->
      individual_uri = individual_uri(resource, individual_entity)
      
      # Individual type statement - marking it as an OWL named individual
      named_individual_statement = Statement.new(
        individual_uri,
        "#{@rdf_namespace}type",
        "#{@owl_namespace}NamedIndividual"
      )
      
      # Class membership statements
      type_statements = Enum.map(individual_entity.types, fn type_entity ->
        class_uri = Uri.resolve(type_entity.class_uri, base_uri)
        Statement.new(individual_uri, "#{@rdf_namespace}type", class_uri)
      end)
      
      # Label statement if present
      label_statements = if individual_entity.label do
        [Statement.new(individual_uri, "#{@rdfs_namespace}label", individual_entity.label)]
      else
        []
      end
      
      # Comment statement if present
      comment_statements = if individual_entity.comment do
        [Statement.new(individual_uri, "#{@rdfs_namespace}comment", individual_entity.comment)]
      else
        []
      end
      
      # Same individual relationships
      same_as_statements = Enum.map(individual_entity.same_as, fn same_entity ->
        same_uri = Uri.resolve(same_entity.individual_uri, base_uri)
        Statement.new(individual_uri, "#{@owl_namespace}sameAs", same_uri)
      end)
      
      # Different individual relationships
      different_from_statements = Enum.map(individual_entity.different_from, fn different_entity ->
        different_uri = Uri.resolve(different_entity.individual_uri, base_uri)
        Statement.new(individual_uri, "#{@owl_namespace}differentFrom", different_uri)
      end)
      
      # Property assertions
      property_assertion_statements = Enum.flat_map(individual_entity.property_assertions, fn assertion_entity ->
        property_uri = Uri.resolve(assertion_entity.property, base_uri)
        
        # Handle the value based on datatype and language
        {value, datatype, language} = 
          if assertion_entity.datatype do
            # Typed literal value
            {assertion_entity.value, assertion_entity.datatype, nil}
          else
            if assertion_entity.language do
              # Language tagged string
              {assertion_entity.value, nil, assertion_entity.language}
            else
              # Plain value - could be a URI or a simple literal
              if is_binary(assertion_entity.value) && Uri.is_absolute_uri?(assertion_entity.value) do
                # URI value
                {assertion_entity.value, nil, nil}
              else
                # Simple literal value
                {assertion_entity.value, nil, nil}
              end
            end
          end
        
        if assertion_entity.negative do
          # Negative property assertion - more complex structure
          
          # Create a blank node for the negative property assertion
          blank_node_id = "_:neg_#{individual_entity.name}_#{assertion_entity.property}"
          
          # Type statement
          type_stmt = Statement.new(
            blank_node_id, 
            "#{@rdf_namespace}type", 
            "#{@owl_namespace}NegativePropertyAssertion"
          )
          
          # Source individual statement
          source_stmt = Statement.new(
            blank_node_id,
            "#{@owl_namespace}sourceIndividual",
            individual_uri
          )
          
          # Property statement
          property_stmt = Statement.new(
            blank_node_id,
            "#{@owl_namespace}assertionProperty",
            property_uri
          )
          
          # Target statement - either object or value depending on value type
          target_stmt = if is_binary(value) && Uri.is_absolute_uri?(value) do
            # Target is an individual
            Statement.new(blank_node_id, "#{@owl_namespace}targetIndividual", value)
          else
            # Target is a literal
            Statement.new(blank_node_id, "#{@owl_namespace}targetValue", value, 
                          datatype: datatype, language: language)
          end
          
          [type_stmt, source_stmt, property_stmt, target_stmt]
        else
          # Regular property assertion
          [Statement.new(individual_uri, property_uri, value, 
                        datatype: datatype, language: language)]
        end
      end)
      
      # Combine all statements
      [named_individual_statement] ++ type_statements ++ 
        label_statements ++ comment_statements ++
        same_as_statements ++ different_from_statements ++
        property_assertion_statements
    end)
  end
  
  @doc """
  Gets all individuals of a specific class.
  """
  def individuals_of_class(resource, class_uri) do
    individuals(resource)
    |> Enum.filter(fn individual_entity ->
      Enum.any?(individual_entity.types, fn type_entity ->
        base_uri = AshRdf.Rdf.Resource.base_uri(resource)
        Uri.resolve(type_entity.class_uri, base_uri) == class_uri
      end)
    end)
  end
  
  @doc """
  Gets all individuals with a specific property assertion.
  """
  def individuals_with_property(resource, property_uri) do
    individuals(resource)
    |> Enum.filter(fn individual_entity ->
      Enum.any?(individual_entity.property_assertions, fn assertion_entity ->
        base_uri = AshRdf.Rdf.Resource.base_uri(resource)
        Uri.resolve(assertion_entity.property, base_uri) == property_uri
      end)
    end)
  end
end