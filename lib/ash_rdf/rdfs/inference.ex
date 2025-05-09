defmodule AshRdf.Rdfs.Inference do
  @moduledoc """
  Provides RDFS inference capabilities.
  
  RDFS inference allows for deriving additional triples based on RDFS
  semantics, such as subclass/subproperty relationships, domain/range
  implications, and more.
  """
  
  alias AshRdf.Rdf.{Statement, Graph}
  
  @rdfs_namespace "http://www.w3.org/2000/01/rdf-schema#"
  @rdf_namespace "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  
  @doc """
  Applies RDFS inference rules to a graph, generating new inferred statements.
  
  The inference is applied until no new statements can be derived.
  """
  def apply_inference(%Graph{} = graph) do
    # Check if inference is enabled
    if inference_enabled?(graph) do
      do_apply_inference(graph)
    else
      graph
    end
  end
  
  defp inference_enabled?(%Graph{} = _graph) do
    # For now, always enable inference
    # In practice, this could check a flag from a dsl_state or graph property
    true
  end
  
  defp do_apply_inference(%Graph{} = graph) do
    # Apply inference rules
    new_graph = graph
    |> apply_subclass_rule()
    |> apply_subproperty_rule()
    |> apply_domain_rule()
    |> apply_range_rule()
    
    # Check if we derived any new statements
    if length(new_graph.statements) > length(graph.statements) do
      # Keep applying inference rules until no new statements are derived
      do_apply_inference(new_graph)
    else
      # No new statements, inference is complete
      new_graph
    end
  end
  
  @doc """
  Applies the rdfs:subClassOf inheritance rule.
  
  If A is a subclass of B, and X is an instance of A, then X is also an instance of B.
  """
  def apply_subclass_rule(%Graph{} = graph) do
    # Find all subclass relationships
    subclass_statements = Graph.find(graph, nil, "#{@rdfs_namespace}subClassOf", nil)
    
    # Find all type statements
    type_statements = Graph.find(graph, nil, "#{@rdf_namespace}type", nil)
    
    # For each subclass relationship and type statement, infer new types
    new_statements = Enum.flat_map(subclass_statements, fn subclass_stmt ->
      subclass = subclass_stmt.subject
      superclass = subclass_stmt.object
      
      # Find instances of the subclass
      instances = Enum.filter(type_statements, fn type_stmt ->
        type_stmt.object == subclass
      end)
      
      # Infer that these instances are also instances of the superclass
      Enum.map(instances, fn instance_stmt ->
        Statement.new(instance_stmt.subject, "#{@rdf_namespace}type", superclass)
      end)
    end)
    
    # Add the new statements to the graph
    Enum.reduce(new_statements, graph, fn statement, acc ->
      # Only add the statement if it doesn't already exist
      if Graph.find_one(acc, statement.subject, statement.predicate, statement.object) do
        acc
      else
        Graph.add(acc, statement)
      end
    end)
  end
  
  @doc """
  Applies the rdfs:subPropertyOf inheritance rule.
  
  If P is a subproperty of Q, and X P Y, then X Q Y.
  """
  def apply_subproperty_rule(%Graph{} = graph) do
    # Find all subproperty relationships
    subproperty_statements = Graph.find(graph, nil, "#{@rdfs_namespace}subPropertyOf", nil)
    
    # For each subproperty relationship, find statements using the subproperty
    # and infer statements using the superproperty
    new_statements = Enum.flat_map(subproperty_statements, fn subprop_stmt ->
      subproperty = subprop_stmt.subject
      superproperty = subprop_stmt.object
      
      # Find statements using the subproperty
      subprop_uses = Graph.find(graph, nil, subproperty, nil)
      
      # Infer statements using the superproperty
      Enum.map(subprop_uses, fn use_stmt ->
        Statement.new(use_stmt.subject, superproperty, use_stmt.object,
          datatype: use_stmt.datatype,
          language: use_stmt.language,
          graph: use_stmt.graph
        )
      end)
    end)
    
    # Add the new statements to the graph
    Enum.reduce(new_statements, graph, fn statement, acc ->
      # Only add the statement if it doesn't already exist
      if Graph.find_one(acc, statement.subject, statement.predicate, statement.object) do
        acc
      else
        Graph.add(acc, statement)
      end
    end)
  end
  
  @doc """
  Applies the rdfs:domain rule.
  
  If P has domain C, and X P Y, then X is an instance of C.
  """
  def apply_domain_rule(%Graph{} = graph) do
    # Find all domain definitions
    domain_statements = Graph.find(graph, nil, "#{@rdfs_namespace}domain", nil)
    
    # For each domain definition, find statements using the property
    # and infer that the subject is an instance of the domain class
    new_statements = Enum.flat_map(domain_statements, fn domain_stmt ->
      property = domain_stmt.subject
      domain_class = domain_stmt.object
      
      # Find statements using the property
      property_uses = Graph.find(graph, nil, property, nil)
      
      # Infer that the subjects are instances of the domain class
      Enum.map(property_uses, fn use_stmt ->
        Statement.new(use_stmt.subject, "#{@rdf_namespace}type", domain_class)
      end)
    end)
    
    # Add the new statements to the graph
    Enum.reduce(new_statements, graph, fn statement, acc ->
      # Only add the statement if it doesn't already exist
      if Graph.find_one(acc, statement.subject, statement.predicate, statement.object) do
        acc
      else
        Graph.add(acc, statement)
      end
    end)
  end
  
  @doc """
  Applies the rdfs:range rule.
  
  If P has range C, and X P Y, then Y is an instance of C.
  """
  def apply_range_rule(%Graph{} = graph) do
    # Find all range definitions
    range_statements = Graph.find(graph, nil, "#{@rdfs_namespace}range", nil)
    
    # For each range definition, find statements using the property
    # and infer that the object is an instance of the range class
    new_statements = Enum.flat_map(range_statements, fn range_stmt ->
      property = range_stmt.subject
      range_class = range_stmt.object
      
      # Find statements using the property
      property_uses = Graph.find(graph, nil, property, nil)
      
      # Infer that the objects are instances of the range class
      # (but only if the object is a URI, not a literal)
      Enum.flat_map(property_uses, fn use_stmt ->
        if not Statement.object_is_literal?(use_stmt) do
          [Statement.new(use_stmt.object, "#{@rdf_namespace}type", range_class)]
        else
          []
        end
      end)
    end)
    
    # Add the new statements to the graph
    Enum.reduce(new_statements, graph, fn statement, acc ->
      # Only add the statement if it doesn't already exist
      if Graph.find_one(acc, statement.subject, statement.predicate, statement.object) do
        acc
      else
        Graph.add(acc, statement)
      end
    end)
  end
end