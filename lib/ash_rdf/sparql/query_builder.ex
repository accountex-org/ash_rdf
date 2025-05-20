defmodule AshRdf.Sparql.QueryBuilder do
  @moduledoc """
  Builds SPARQL queries from Ash queries and filters.
  
  This module translates Ash queries into their SPARQL equivalents, handling
  filtering, sorting, pagination, and relationship loading.
  """

  alias Ash.Filter
  alias Ash.Query
  alias Ash.Sort
  alias AshRdf.Rdf.Uri

  @doc """
  Builds a SPARQL SELECT query from an Ash query.
  """
  @spec build_select(Ash.Query.t()) :: String.t()
  def build_select(query) do
    resource = Query.resource(query)
    base_uri = get_resource_base_uri(resource)
    
    # Get variables and constraints from filters
    {where_clauses, variables, params, bindings} = 
      query
      |> Query.filter()
      |> build_filter_clauses(resource, %{}, 1)
    
    # Add sorting directives
    {order_clauses, variables, _count} = 
      query
      |> Query.sort()
      |> build_sort_clauses(variables, length(variables) + 1)
    
    # Add pagination
    {limit_offset, bindings} = build_limit_offset(query, bindings)
    
    # Build the SELECT query with all components
    """
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    #{build_prefixes(resource)}
    
    SELECT #{build_select_variables(variables, resource)}
    WHERE {
      #{where_clauses}
      #{build_type_constraint(resource)}
    }
    #{order_clauses}
    #{limit_offset}
    """
  end

  @doc """
  Builds a SPARQL CONSTRUCT query from an Ash query.
  """
  @spec build_construct(Ash.Query.t()) :: String.t()
  def build_construct(query) do
    resource = Query.resource(query)
    base_uri = get_resource_base_uri(resource)
    
    # Get variables and constraints from filters
    {where_clauses, variables, params, bindings} = 
      query
      |> Query.filter()
      |> build_filter_clauses(resource, %{}, 1)
    
    # Add sorting directives
    {order_clauses, variables, _count} = 
      query
      |> Query.sort()
      |> build_sort_clauses(variables, length(variables) + 1)
    
    # Add pagination
    {limit_offset, bindings} = build_limit_offset(query, bindings)
    
    # Build the CONSTRUCT query
    """
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    #{build_prefixes(resource)}
    
    CONSTRUCT {
      ?s ?p ?o .
    }
    WHERE {
      #{where_clauses}
      #{build_type_constraint(resource)}
      ?s ?p ?o .
    }
    #{order_clauses}
    #{limit_offset}
    """
  end

  @doc """
  Builds a SPARQL INSERT query for a new resource.
  """
  @spec build_insert(Ash.Changeset.t()) :: String.t()
  def build_insert(changeset) do
    resource = Ash.Changeset.resource(changeset)
    base_uri = get_resource_base_uri(resource)
    attributes = Ash.Changeset.attributes(changeset)
    
    # Get the URI for the resource
    resource_uri = get_resource_uri(changeset)
    
    # Build triples for each attribute
    attribute_triples = 
      attributes
      |> Enum.map(fn {attr_name, value} ->
        predicate = get_attribute_predicate(resource, attr_name)
        object = build_object_value(value)
        "  <#{resource_uri}> <#{predicate}> #{object} ."
      end)
      |> Enum.join("\n")
    
    # Add the type triple
    type_triple = "  <#{resource_uri}> rdf:type <#{get_resource_class_uri(resource)}> ."
    
    """
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    #{build_prefixes(resource)}
    
    INSERT DATA {
    #{type_triple}
    #{attribute_triples}
    }
    """
  end

  @doc """
  Builds a SPARQL DELETE/INSERT query for updating a resource.
  """
  @spec build_update(Ash.Changeset.t()) :: String.t()
  def build_update(changeset) do
    resource = Ash.Changeset.resource(changeset)
    base_uri = get_resource_base_uri(resource)
    attributes = Ash.Changeset.attributes(changeset)
    
    # Get the URI for the resource
    resource_uri = get_resource_uri(changeset)
    
    # Build DELETE triples for each attribute being updated
    delete_triples = 
      attributes
      |> Enum.map(fn {attr_name, _value} ->
        predicate = get_attribute_predicate(resource, attr_name)
        "  <#{resource_uri}> <#{predicate}> ?old_#{attr_name} ."
      end)
      |> Enum.join("\n")
    
    # Build INSERT triples for each attribute
    insert_triples = 
      attributes
      |> Enum.map(fn {attr_name, value} ->
        predicate = get_attribute_predicate(resource, attr_name)
        object = build_object_value(value)
        "  <#{resource_uri}> <#{predicate}> #{object} ."
      end)
      |> Enum.join("\n")
    
    # Build WHERE clauses to find the old values
    where_triples = 
      attributes
      |> Enum.map(fn {attr_name, _value} ->
        predicate = get_attribute_predicate(resource, attr_name)
        "  OPTIONAL { <#{resource_uri}> <#{predicate}> ?old_#{attr_name} . }"
      end)
      |> Enum.join("\n")
    
    """
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    #{build_prefixes(resource)}
    
    DELETE {
    #{delete_triples}
    }
    INSERT {
    #{insert_triples}
    }
    WHERE {
    #{where_triples}
    }
    """
  end

  @doc """
  Builds a SPARQL DELETE query for destroying a resource.
  """
  @spec build_delete(Ash.Changeset.t() | Ash.Resource.record()) :: String.t()
  def build_delete(record_or_changeset) do
    {resource, resource_uri} = case record_or_changeset do
      %Ash.Changeset{} = changeset ->
        {Ash.Changeset.resource(changeset), get_resource_uri(changeset)}
      record ->
        resource = Ash.Resource.resource(record)
        {resource, get_record_uri(record, resource)}
    end
    
    """
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    #{build_prefixes(resource)}
    
    DELETE WHERE {
      <#{resource_uri}> ?p ?o .
    }
    """
  end

  # Private helpers

  defp build_filter_clauses(nil, _resource, variables, var_count) do
    {"", variables, [], %{}}
  end

  defp build_filter_clauses(filter, resource, variables, var_count) do
    build_filter_predicate(filter, resource, variables, var_count)
  end

  defp build_filter_predicate(%Filter{predicate: nil}, _resource, variables, var_count) do
    {"", variables, [], %{}}
  end

  defp build_filter_predicate(%Filter{predicate: {logical_op, predicates}}, resource, variables, var_count)
       when logical_op in [:and, :or] do
    # Build clauses for each predicate
    {clauses, vars, params, bindings, new_var_count} =
      Enum.reduce(predicates, {[], variables, [], %{}, var_count}, fn pred, {cls, vs, ps, bs, vc} ->
        {clause, new_vars, new_params, new_bindings, new_vc} = build_filter_predicate(pred, resource, vs, vc)
        {[clause | cls], new_vars, ps ++ new_params, Map.merge(bs, new_bindings), new_vc}
      end)

    # Join with appropriate logical operator
    op_str = if logical_op == :and, do: " . ", else: " UNION "
    
    if logical_op == :or do
      combined = 
        clauses
        |> Enum.map(fn clause -> "{ #{clause} }" end)
        |> Enum.join(op_str)
      
      {combined, vars, params, bindings, new_var_count}
    else
      combined = Enum.join(clauses, op_str)
      {combined, vars, params, bindings, new_var_count}
    end
  end

  defp build_filter_predicate(%Filter{predicate: {attribute, operator, value}}, resource, variables, var_count) do
    # Map Ash operators to SPARQL operators and build filter expressions
    predicate = get_attribute_predicate(resource, attribute)
    subject_var = "?s"
    
    {sparql_expr, params, bindings, new_var_count} = 
      case operator do
        :eq -> 
          object = build_object_value(value)
          {"#{subject_var} <#{predicate}> #{object}", [], %{}, var_count}
          
        :not_eq -> 
          object = build_object_value(value)
          {"#{subject_var} <#{predicate}> ?val#{var_count} . FILTER(?val#{var_count} != #{object})", 
           [], %{}, var_count + 1}
          
        :in ->
          values = 
            value
            |> Enum.map(&build_object_value/1)
            |> Enum.join(", ")
          
          {"#{subject_var} <#{predicate}> ?val#{var_count} . FILTER(?val#{var_count} IN (#{values}))",
           [], %{}, var_count + 1}
           
        :not_in ->
          values = 
            value
            |> Enum.map(&build_object_value/1)
            |> Enum.join(", ")
          
          {"#{subject_var} <#{predicate}> ?val#{var_count} . FILTER(?val#{var_count} NOT IN (#{values}))",
           [], %{}, var_count + 1}
           
        :like ->
          # SPARQL REGEX for LIKE
          {"#{subject_var} <#{predicate}> ?val#{var_count} . FILTER(REGEX(STR(?val#{var_count}), \"#{escape_regex(value)}\", \"i\"))",
           [], %{}, var_count + 1}
           
        :not_like ->
          {"#{subject_var} <#{predicate}> ?val#{var_count} . FILTER(!REGEX(STR(?val#{var_count}), \"#{escape_regex(value)}\", \"i\"))",
           [], %{}, var_count + 1}
           
        :gt ->
          object = build_object_value(value)
          {"#{subject_var} <#{predicate}> ?val#{var_count} . FILTER(?val#{var_count} > #{object})",
           [], %{}, var_count + 1}
           
        :gte ->
          object = build_object_value(value)
          {"#{subject_var} <#{predicate}> ?val#{var_count} . FILTER(?val#{var_count} >= #{object})",
           [], %{}, var_count + 1}
           
        :lt ->
          object = build_object_value(value)
          {"#{subject_var} <#{predicate}> ?val#{var_count} . FILTER(?val#{var_count} < #{object})",
           [], %{}, var_count + 1}
           
        :lte ->
          object = build_object_value(value)
          {"#{subject_var} <#{predicate}> ?val#{var_count} . FILTER(?val#{var_count} <= #{object})",
           [], %{}, var_count + 1}
           
        :is_nil ->
          if value do
            # NOT EXISTS pattern for IS NULL
            {"FILTER NOT EXISTS { #{subject_var} <#{predicate}> ?val#{var_count} }",
             [], %{}, var_count + 1}
          else
            # EXISTS pattern for IS NOT NULL
            {"FILTER EXISTS { #{subject_var} <#{predicate}> ?val#{var_count} }",
             [], %{}, var_count + 1}
          end
          
        _ ->
          raise "Unsupported filter operator: #{operator}"
      end
    
    # Update variables map with attribute
    var_name = "val#{var_count}"
    new_variables = Map.put(variables, var_name, attribute)
    
    {sparql_expr, new_variables, params, bindings, new_var_count}
  end

  defp build_sort_clauses([], variables, var_count) do
    {"", variables, var_count}
  end

  defp build_sort_clauses(sorts, variables, var_count) do
    {clauses, new_variables, new_var_count} =
      Enum.reduce(sorts, {[], variables, var_count}, fn %Sort{attribute: attr, direction: dir}, {cls, vars, vc} ->
        sort_dir = if dir == :asc, do: "ASC", else: "DESC"
        var_name = "order#{vc}"
        clause = "#{sort_dir}(?#{var_name})"
        updated_vars = Map.put(vars, var_name, attr)
        {[clause | cls], updated_vars, vc + 1}
      end)
    
    # Add variables to WHERE clause for sorting
    where_vars = 
      variables
      |> Enum.filter(fn {var, _} -> String.starts_with?(var, "order") end)
      |> Enum.map(fn {var, attr} -> 
        "?s <#{attr}> ?#{var} ."
      end)
      |> Enum.join("\n")
    
    sort_clause = 
      if Enum.empty?(clauses) do
        ""
      else
        "ORDER BY " <> Enum.join(Enum.reverse(clauses), " ")
      end
    
    {sort_clause, new_variables, new_var_count}
  end

  defp build_limit_offset(query, bindings) do
    limit = Query.limit(query)
    offset = Query.offset(query)
    
    limit_clause = if limit, do: "LIMIT #{limit}", else: ""
    offset_clause = if offset, do: "OFFSET #{offset}", else: ""
    
    {"#{limit_clause} #{offset_clause}", bindings}
  end

  defp build_prefixes(resource) do
    # Extract namespace prefixes from resource configuration
    prefixes = AshRdf.Dsl.Info.prefixes(resource)
    
    prefixes
    |> Enum.map(fn {prefix, uri} ->
      "PREFIX #{prefix}: <#{uri}>"
    end)
    |> Enum.join("\n")
  end

  defp build_select_variables(variables, resource) do
    # Include default variable for subject
    base_vars = ["?s"]
    
    # Add requested attributes as variables
    attr_vars = 
      resource
      |> Ash.Resource.Info.attributes()
      |> Enum.map(fn %{name: name} = attr ->
        # Use the variable name if it exists in the variables map
        var = 
          variables
          |> Enum.find(fn {_var, attr_name} -> attr_name == name end)
          |> case do
            {var, _} -> "?#{var}"
            nil -> "?#{name}"
          end
        
        var
      end)
    
    # Combine all variables
    (base_vars ++ attr_vars)
    |> Enum.uniq()
    |> Enum.join(" ")
  end

  defp build_type_constraint(resource) do
    class_uri = get_resource_class_uri(resource)
    "?s rdf:type <#{class_uri}> ."
  end

  defp get_resource_base_uri(resource) do
    AshRdf.Dsl.Info.base_uri(resource)
  end

  defp get_resource_class_uri(resource) do
    AshRdf.Dsl.Info.class_uri(resource)
  end

  defp get_attribute_predicate(resource, attribute) when is_atom(attribute) do
    # Convert attribute to predicate URI
    attribute_str = to_string(attribute)
    base_uri = get_resource_base_uri(resource)
    
    # Look up predicate in resource configuration
    case AshRdf.Dsl.Info.property_uri(resource, attribute) do
      nil -> 
        # Default to concatenating base URI with attribute name
        Uri.join(base_uri, attribute_str)
      predicate_uri -> 
        predicate_uri
    end
  end

  defp get_attribute_predicate(_resource, attribute) when is_binary(attribute) do
    # Assume a full URI is provided
    attribute
  end

  defp get_resource_uri(changeset) do
    resource = Ash.Changeset.resource(changeset)
    base_uri = get_resource_base_uri(resource)
    
    # Get the primary key attribute
    pk_attr = 
      resource
      |> Ash.Resource.Info.primary_key()
      |> List.first()
    
    # Get the primary key value from the changeset
    pk_value = Ash.Changeset.get_attribute(changeset, pk_attr)
    
    # Build the resource URI
    Uri.join(base_uri, to_string(pk_value))
  end

  defp get_record_uri(record, resource) do
    base_uri = get_resource_base_uri(resource)
    
    # Get the primary key attribute
    pk_attr = 
      resource
      |> Ash.Resource.Info.primary_key()
      |> List.first()
    
    # Get the primary key value from the record
    pk_value = Map.get(record, pk_attr)
    
    # Build the resource URI
    Uri.join(base_uri, to_string(pk_value))
  end

  defp build_object_value(value) when is_binary(value) do
    "\"#{escape_string(value)}\""
  end

  defp build_object_value(value) when is_integer(value) do
    "\"#{value}\"^^xsd:integer"
  end

  defp build_object_value(value) when is_float(value) do
    "\"#{value}\"^^xsd:decimal"
  end

  defp build_object_value(true) do
    "\"true\"^^xsd:boolean"
  end

  defp build_object_value(false) do
    "\"false\"^^xsd:boolean"
  end

  defp build_object_value(%DateTime{} = dt) do
    iso_dt = DateTime.to_iso8601(dt)
    "\"#{iso_dt}\"^^xsd:dateTime"
  end

  defp build_object_value(%Date{} = d) do
    iso_date = Date.to_iso8601(d)
    "\"#{iso_date}\"^^xsd:date"
  end

  defp build_object_value(nil) do
    # This shouldn't happen in most cases since IS NULL is handled differently
    "\"\"" 
  end

  defp build_object_value(value) do
    # For other types, convert to string
    "\"#{escape_string(to_string(value))}\""
  end

  defp escape_string(string) do
    string
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
    |> String.replace("\t", "\\t")
  end

  defp escape_regex(pattern) do
    pattern
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace(".", "\\.")
    |> String.replace("^", "\\^")
    |> String.replace("$", "\\$")
    |> String.replace("|", "\\|")
    |> String.replace("(", "\\(")
    |> String.replace(")", "\\)")
    |> String.replace("[", "\\[")
    |> String.replace("]", "\\]")
    |> String.replace("*", "\\*")
    |> String.replace("+", "\\+")
    |> String.replace("?", "\\?")
    |> String.replace("{", "\\{")
    |> String.replace("}", "\\}")
  end
end