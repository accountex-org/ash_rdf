defmodule AshRdf.Verifiers.ValidateUri do
  @moduledoc """
  Verifies that all URIs in the RDF resource are valid according to standards.
  
  This verifier checks:
  - Base URIs are absolute and properly formatted
  - Resource identifiers follow valid URI syntax
  - Property URIs are valid absolute URIs
  - Class URIs are valid absolute URIs
  """
  
  use Spark.Dsl.Verifier
  
  alias Spark.Error.DslError
  import Spark.Dsl.Extension, only: [get_entities: 2]
  
  @doc """
  Verifies URI validity throughout the RDF resource definition.
  """
  def verify(dsl_state) do
    with :ok <- verify_base_uri(dsl_state),
         :ok <- verify_resource_uris(dsl_state),
         :ok <- verify_property_uris(dsl_state),
         :ok <- verify_class_uris(dsl_state) do
      :ok
    end
  end
  
  # Verify that the base URI is present and well-formed
  defp verify_base_uri(dsl_state) do
    base_uri = Spark.Dsl.Extension.get_opt(dsl_state, [:rdf], :base_uri)
    
    cond do
      is_nil(base_uri) ->
        {:error, DslError.exception(message: "A base URI is required for RDF resources")}
      
      not is_absolute_uri?(base_uri) ->
        {:error, DslError.exception(message: "Base URI '#{base_uri}' must be an absolute URI starting with http:// or https://")}
      
      not String.ends_with?(base_uri, ["/", "#"]) ->
        {:error, DslError.exception(message: "Base URI '#{base_uri}' should end with '/' or '#'")}
      
      true ->
        :ok
    end
  end
  
  # Verify that all resource URIs are valid
  defp verify_resource_uris(dsl_state) do
    resources = get_entities(dsl_state, [:rdf, :resource])
    
    Enum.reduce_while(resources, :ok, fn resource, :ok ->
      case verify_identifier(resource.identifier) do
        :ok -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end
  
  # Verify that all property URIs are valid
  defp verify_property_uris(dsl_state) do
    properties = get_entities(dsl_state, [:rdf, :property])
    
    Enum.reduce_while(properties, :ok, fn property, :ok ->
      case verify_identifier(property.identifier) do
        :ok -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end
  
  # Verify that all class URIs are valid
  defp verify_class_uris(dsl_state) do
    # Check RDFS classes if they exist
    rdfs_classes = get_entities(dsl_state, [:rdfs, :class])
    
    rdfs_result = Enum.reduce_while(rdfs_classes, :ok, fn class, :ok ->
      case verify_identifier(class.identifier) do
        :ok -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    
    case rdfs_result do
      :ok ->
        # Check OWL classes if they exist
        owl_classes = get_entities(dsl_state, [:owl, :class])
        
        Enum.reduce_while(owl_classes, :ok, fn class, :ok ->
          case verify_identifier(class.identifier) do
            :ok -> {:cont, :ok}
            {:error, error} -> {:halt, {:error, error}}
          end
        end)
      
      error ->
        error
    end
  end
  
  # Verify an identifier - could be a URI or a reference to be expanded later
  defp verify_identifier(nil), do: :ok
  
  defp verify_identifier(identifier) when is_binary(identifier) do
    cond do
      is_absolute_uri?(identifier) ->
        :ok
      
      is_valid_local_name?(identifier) ->
        :ok
      
      true ->
        {:error, DslError.exception(message: "'#{identifier}' is neither a valid absolute URI nor a valid local name")}
    end
  end
  
  # Check if a string is an absolute URI by checking for scheme:// pattern
  defp is_absolute_uri?(uri) when is_binary(uri) do
    uri_pattern = ~r/^[a-z][a-z0-9+.-]*:\/\/.+/i
    Regex.match?(uri_pattern, uri)
  end
  
  defp is_absolute_uri?(_), do: false
  
  # Check if a string is a valid local name (NCName in XML parlance)
  # This is simplified - for a full NCName validation see XML spec
  defp is_valid_local_name?(name) when is_binary(name) do
    local_name_pattern = ~r/^[a-zA-Z_][a-zA-Z0-9_.-]*$/
    Regex.match?(local_name_pattern, name)
  end
  
  defp is_valid_local_name?(_), do: false
end