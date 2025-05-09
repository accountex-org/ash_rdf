defmodule AshRdf.Owl.Class do
  @moduledoc """
  Functions for working with OWL classes.
  """
  
  alias Spark.Dsl.Extension
  alias AshRdf.Rdf.{Statement, Uri}
  
  @owl_namespace "http://www.w3.org/2002/07/owl#"
  @rdf_namespace "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  @rdfs_namespace "http://www.w3.org/2000/01/rdf-schema#"
  
  @doc """
  Gets all OWL classes defined in a resource.
  """
  def classes(resource) do
    Extension.get_entities(resource, [:owl, :class])
  end
  
  @doc """
  Gets a specific OWL class from a resource by name.
  """
  def class_by_name(resource, name) do
    classes(resource)
    |> Enum.find(&(&1.name == name))
  end
  
  @doc """
  Gets the URI for an OWL class.
  """
  def class_uri(resource, class_entity) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    Uri.resolve(class_entity.uri || to_string(class_entity.name), base_uri)
  end
  
  @doc """
  Converts OWL class definitions to RDF statements.
  """
  def to_rdf(resource) do
    base_uri = AshRdf.Rdf.Resource.base_uri(resource)
    
    # Generate statements for each class
    Enum.flat_map(classes(resource), fn class_entity ->
      class_uri = class_uri(resource, class_entity)
      
      # Class type statement
      type_statement = Statement.new(
        class_uri,
        "#{@rdf_namespace}type",
        "#{@owl_namespace}Class"
      )
      
      # Label statement if present
      label_statements = if class_entity.label do
        [Statement.new(class_uri, "#{@rdfs_namespace}label", class_entity.label)]
      else
        []
      end
      
      # Comment statement if present
      comment_statements = if class_entity.comment do
        [Statement.new(class_uri, "#{@rdfs_namespace}comment", class_entity.comment)]
      else
        []
      end
      
      # Equivalent class relationships
      equivalent_class_statements = Enum.map(class_entity.equivalent_to, fn equivalent_entity ->
        eq_uri = Uri.resolve(equivalent_entity.class_uri, base_uri)
        Statement.new(class_uri, "#{@owl_namespace}equivalentClass", eq_uri)
      end)
      
      # Disjoint class relationships
      disjoint_class_statements = Enum.map(class_entity.disjoint_with, fn disjoint_entity ->
        disj_uri = Uri.resolve(disjoint_entity.class_uri, base_uri)
        Statement.new(class_uri, "#{@owl_namespace}disjointWith", disj_uri)
      end)
      
      # Intersection of class expressions
      intersection_statements = if class_entity.intersection_of && length(class_entity.intersection_of) > 0 do
        # Create a blank node for the intersection
        blank_node_id = "_:intersection_#{class_entity.name}"
        
        # Create the intersection type statement
        intersection_type = Statement.new(
          blank_node_id, 
          "#{@rdf_namespace}type",
          "#{@owl_namespace}Class"
        )
        
        # Create the statement connecting class to intersection
        class_intersection = Statement.new(
          class_uri,
          "#{@owl_namespace}equivalentClass",
          blank_node_id
        )
        
        # Create list of class URIs in the intersection
        intersection_members = Enum.map(class_entity.intersection_of, fn member_entity ->
          Uri.resolve(member_entity.class_uri, base_uri)
        end)
        
        # Create rdf:List representation of the intersection members
        {list_node, list_statements} = create_rdf_list(blank_node_id, intersection_members)
        
        # Connect the blank node to the list
        intersection_list = Statement.new(
          blank_node_id,
          "#{@owl_namespace}intersectionOf",
          list_node
        )
        
        # Combine all statements
        [intersection_type, class_intersection, intersection_list] ++ list_statements
      else
        []
      end
      
      # Union of class expressions
      union_statements = if class_entity.union_of && length(class_entity.union_of) > 0 do
        # Create a blank node for the union
        blank_node_id = "_:union_#{class_entity.name}"
        
        # Create the union type statement
        union_type = Statement.new(
          blank_node_id, 
          "#{@rdf_namespace}type",
          "#{@owl_namespace}Class"
        )
        
        # Create the statement connecting class to union
        class_union = Statement.new(
          class_uri,
          "#{@owl_namespace}equivalentClass",
          blank_node_id
        )
        
        # Create list of class URIs in the union
        union_members = Enum.map(class_entity.union_of, fn member_entity ->
          Uri.resolve(member_entity.class_uri, base_uri)
        end)
        
        # Create rdf:List representation of the union members
        {list_node, list_statements} = create_rdf_list(blank_node_id, union_members)
        
        # Connect the blank node to the list
        union_list = Statement.new(
          blank_node_id,
          "#{@owl_namespace}unionOf",
          list_node
        )
        
        # Combine all statements
        [union_type, class_union, union_list] ++ list_statements
      else
        []
      end
      
      # Complement of class expressions
      complement_statements = Enum.flat_map(class_entity.complement_of, fn complement_entity ->
        # Create a blank node for the complement
        blank_node_id = "_:complement_#{class_entity.name}_#{complement_entity.class_uri}"
        
        # Create the complement type statement
        complement_type = Statement.new(
          blank_node_id, 
          "#{@rdf_namespace}type",
          "#{@owl_namespace}Class"
        )
        
        # Create the statement connecting class to complement
        class_complement = Statement.new(
          class_uri,
          "#{@owl_namespace}equivalentClass",
          blank_node_id
        )
        
        # Create the complementOf statement
        complement_uri = Uri.resolve(complement_entity.class_uri, base_uri)
        complement_of = Statement.new(
          blank_node_id,
          "#{@owl_namespace}complementOf",
          complement_uri
        )
        
        [complement_type, class_complement, complement_of]
      end)
      
      # Deprecated flag
      deprecated_statements = if class_entity.deprecated do
        [Statement.new(class_uri, "#{@owl_namespace}deprecated", "true", datatype: "#{@rdf_namespace}boolean")]
      else
        []
      end
      
      # Combine all statements
      [type_statement] ++ label_statements ++ comment_statements ++ 
        equivalent_class_statements ++ disjoint_class_statements ++
        intersection_statements ++ union_statements ++ complement_statements ++
        deprecated_statements
    end)
  end
  
  # Helper function to create an RDF list representation
  defp create_rdf_list(base_id, items) do
    create_rdf_list_helper(items, 0, base_id)
  end
  
  defp create_rdf_list_helper([], _index, _base_id) do
    # Empty list is represented by rdf:nil
    {"#{@rdf_namespace}nil", []}
  end
  
  defp create_rdf_list_helper([item | rest], index, base_id) do
    # Create a blank node for this list cell
    list_node = "#{base_id}_list_#{index}"
    
    # Create statements for the current list cell
    first_stmt = Statement.new(list_node, "#{@rdf_namespace}first", item)
    
    # Recursively create the rest of the list
    {rest_node, rest_statements} = create_rdf_list_helper(rest, index + 1, base_id)
    
    # Connect current cell to the rest
    rest_stmt = Statement.new(list_node, "#{@rdf_namespace}rest", rest_node)
    
    # Return the list node and all statements
    {list_node, [first_stmt, rest_stmt] ++ rest_statements}
  end
end