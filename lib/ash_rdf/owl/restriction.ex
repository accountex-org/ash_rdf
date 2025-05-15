defmodule AshRdf.Owl.Restriction do
  @moduledoc """
  Functions for working with OWL restrictions.
  """
  
  alias Spark.Dsl.Extension
  alias AshRdf.Rdf.{Statement, Uri}
  
  @owl_namespace "http://www.w3.org/2002/07/owl#"
  @rdf_namespace "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  
  @doc """
  Gets all OWL restrictions defined in a resource.
  """
  def restrictions(resource) do
    Extension.get_entities(resource, [:owl, :restriction])
  end
  
  @doc """
  Gets a specific OWL restriction from a resource by name.
  """
  def restriction_by_name(resource, name) do
    restrictions(resource)
    |> Enum.find(&(&1.name == name))
  end
  
  @doc """
  Converts OWL restriction definitions to RDF statements.
  """
  def to_rdf(resource) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    
    # Generate statements for each restriction
    Enum.flat_map(restrictions(resource), fn restriction_entity ->
      # Create a blank node for the restriction
      restriction_node = "_:restriction_#{restriction_entity.name}"
      
      # Basic restriction type statements
      basic_statements = [
        # This is a class
        Statement.new(restriction_node, "#{@rdf_namespace}type", "#{@owl_namespace}Class"),
        # This is a restriction
        Statement.new(restriction_node, "#{@rdf_namespace}type", "#{@owl_namespace}Restriction"),
        # This restriction is on this property
        Statement.new(
          restriction_node, 
          "#{@owl_namespace}onProperty", 
          Uri.resolve(restriction_entity.on_property, base_uri)
        )
      ]
      
      # Cardinality restriction statements
      cardinality_statements = cond do
        # Min cardinality
        restriction_entity.min_cardinality != nil ->
          [Statement.new(
            restriction_node,
            "#{@owl_namespace}minCardinality",
            restriction_entity.min_cardinality,
            datatype: "#{@rdf_namespace}nonNegativeInteger"
          )]
          
        # Max cardinality  
        restriction_entity.max_cardinality != nil ->
          [Statement.new(
            restriction_node,
            "#{@owl_namespace}maxCardinality",
            restriction_entity.max_cardinality,
            datatype: "#{@rdf_namespace}nonNegativeInteger"
          )]
          
        # Exact cardinality  
        restriction_entity.exact_cardinality != nil ->
          [Statement.new(
            restriction_node,
            "#{@owl_namespace}cardinality",
            restriction_entity.exact_cardinality,
            datatype: "#{@rdf_namespace}nonNegativeInteger"
          )]
          
        # No simple cardinality restrictions
        true ->
          []
      end
      
      # Qualified cardinality restriction statements
      qualified_cardinality_statements = 
        if restriction_entity.qualified_on_class != nil do
          qualified_class_uri = Uri.resolve(restriction_entity.qualified_on_class, base_uri)
          
          # The base restriction statement linking to the class
          class_stmt = Statement.new(
            restriction_node,
            "#{@owl_namespace}onClass",
            qualified_class_uri
          )
          
          # The actual cardinality statements
          qualified_stmts = cond do
            # Min qualified cardinality
            restriction_entity.min_qualified_cardinality != nil ->
              [Statement.new(
                restriction_node,
                "#{@owl_namespace}minQualifiedCardinality",
                restriction_entity.min_qualified_cardinality,
                datatype: "#{@rdf_namespace}nonNegativeInteger"
              )]
              
            # Max qualified cardinality  
            restriction_entity.max_qualified_cardinality != nil ->
              [Statement.new(
                restriction_node,
                "#{@owl_namespace}maxQualifiedCardinality",
                restriction_entity.max_qualified_cardinality,
                datatype: "#{@rdf_namespace}nonNegativeInteger"
              )]
              
            # Exact qualified cardinality  
            restriction_entity.exact_qualified_cardinality != nil ->
              [Statement.new(
                restriction_node,
                "#{@owl_namespace}qualifiedCardinality",
                restriction_entity.exact_qualified_cardinality,
                datatype: "#{@rdf_namespace}nonNegativeInteger"
              )]
              
            # No qualified cardinality restrictions
            true ->
              []
          end
          
          [class_stmt | qualified_stmts]
        else
          []
        end
      
      # Value restriction statements
      value_restriction_statements = cond do
        # someValuesFrom restriction
        restriction_entity.some_values_from != nil ->
          class_uri = Uri.resolve(restriction_entity.some_values_from, base_uri)
          [Statement.new(
            restriction_node,
            "#{@owl_namespace}someValuesFrom",
            class_uri
          )]
          
        # allValuesFrom restriction  
        restriction_entity.all_values_from != nil ->
          class_uri = Uri.resolve(restriction_entity.all_values_from, base_uri)
          [Statement.new(
            restriction_node,
            "#{@owl_namespace}allValuesFrom",
            class_uri
          )]
          
        # hasValue restriction  
        restriction_entity.has_value != nil ->
          value = restriction_entity.has_value
          
          # The value could be a URI or a literal
          if is_binary(value) && Uri.is_absolute_uri?(value) do
            [Statement.new(
              restriction_node,
              "#{@owl_namespace}hasValue",
              value
            )]
          else
            # For simplicity, treating non-URI values as simple literals
            # A more complete implementation would handle datatypes
            [Statement.new(
              restriction_node,
              "#{@owl_namespace}hasValue",
              value
            )]
          end
          
        # hasSelf restriction  
        restriction_entity.has_self == true ->
          [Statement.new(
            restriction_node,
            "#{@owl_namespace}hasSelf",
            "true",
            datatype: "#{@rdf_namespace}boolean"
          )]
          
        # No value restrictions
        true ->
          []
      end
      
      # Combine all statements
      basic_statements ++ cardinality_statements ++ 
        qualified_cardinality_statements ++ value_restriction_statements
    end)
  end
  
  @doc """
  Creates restriction statements for a class.
  
  This generates statements connecting a class to the restrictions that apply to it.
  """
  def create_class_restriction_statements(_resource, _class_entity) do
    # This would typically be part of the class definition
    # But restrictions often need to be linked to classes
    []
  end
end