defmodule AshRdf.Verifiers.ValidateUriTest do
  use ExUnit.Case

  alias AshRdf.Verifiers.ValidateUri
  alias Spark.Dsl.Transformer
  
  # Helper function to create a basic DSL state for testing
  defp dsl_state_with_base_uri(base_uri) do
    %{
      sections: %{
        rdf: %{
          options: %{
            base_uri: base_uri
          },
          entities: %{
            resource: [],
            property: []
          }
        },
        rdfs: %{
          entities: %{
            class: []
          }
        },
        owl: %{
          entities: %{
            class: []
          }
        }
      }
    }
  end

  # Helper to create a DSL state with resources
  defp dsl_state_with_resources(resources) do
    base = dsl_state_with_base_uri("http://example.org/")
    
    put_in(
      base,
      [:sections, :rdf, :entities, :resource],
      resources
    )
  end

  # Helper to create a DSL state with properties
  defp dsl_state_with_properties(properties) do
    base = dsl_state_with_base_uri("http://example.org/")
    
    put_in(
      base,
      [:sections, :rdf, :entities, :property],
      properties
    )
  end

  # Helper to create a DSL state with RDFS classes
  defp dsl_state_with_rdfs_classes(classes) do
    base = dsl_state_with_base_uri("http://example.org/")
    
    put_in(
      base,
      [:sections, :rdfs, :entities, :class],
      classes
    )
  end

  # Helper to create a DSL state with OWL classes
  defp dsl_state_with_owl_classes(classes) do
    base = dsl_state_with_base_uri("http://example.org/")
    
    put_in(
      base,
      [:sections, :owl, :entities, :class],
      classes
    )
  end

  describe "verify/1 with base_uri" do
    test "accepts valid absolute URIs ending with / or #" do
      assert :ok = ValidateUri.verify(dsl_state_with_base_uri("http://example.org/"))
      assert :ok = ValidateUri.verify(dsl_state_with_base_uri("https://example.org/ontology#"))
    end

    test "rejects missing base_uri" do
      dsl_state = dsl_state_with_base_uri(nil)
      
      assert {:error, error} = ValidateUri.verify(dsl_state)
      assert error.message =~ "A base URI is required"
    end

    test "rejects non-absolute base_uri" do
      dsl_state = dsl_state_with_base_uri("example.org/")
      
      assert {:error, error} = ValidateUri.verify(dsl_state)
      assert error.message =~ "must be an absolute URI"
    end

    test "rejects base_uri without trailing / or #" do
      dsl_state = dsl_state_with_base_uri("http://example.org")
      
      assert {:error, error} = ValidateUri.verify(dsl_state)
      assert error.message =~ "should end with '/' or '#'"
    end
  end

  describe "verify/1 with resources" do
    test "accepts resources with valid absolute URIs" do
      resources = [
        %{identifier: "http://example.org/resource1"},
        %{identifier: "http://example.com/resource2"}
      ]
      
      assert :ok = ValidateUri.verify(dsl_state_with_resources(resources))
    end

    test "accepts resources with valid local names" do
      resources = [
        %{identifier: "resource1"},
        %{identifier: "resource_2"}
      ]
      
      assert :ok = ValidateUri.verify(dsl_state_with_resources(resources))
    end

    test "rejects resources with invalid identifiers" do
      resources = [
        %{identifier: "valid_resource"},
        %{identifier: "invalid resource with spaces"}
      ]
      
      assert {:error, error} = ValidateUri.verify(dsl_state_with_resources(resources))
      assert error.message =~ "invalid resource with spaces"
    end
  end

  describe "verify/1 with properties" do
    test "accepts properties with valid absolute URIs" do
      properties = [
        %{identifier: "http://example.org/property1"},
        %{identifier: "http://example.com/property2"}
      ]
      
      assert :ok = ValidateUri.verify(dsl_state_with_properties(properties))
    end

    test "accepts properties with valid local names" do
      properties = [
        %{identifier: "property1"},
        %{identifier: "property_2"}
      ]
      
      assert :ok = ValidateUri.verify(dsl_state_with_properties(properties))
    end

    test "rejects properties with invalid identifiers" do
      properties = [
        %{identifier: "valid_property"},
        %{identifier: "invalid!property"}
      ]
      
      assert {:error, error} = ValidateUri.verify(dsl_state_with_properties(properties))
      assert error.message =~ "invalid!property"
    end
  end

  describe "verify/1 with RDFS classes" do
    test "accepts RDFS classes with valid absolute URIs" do
      classes = [
        %{identifier: "http://example.org/Class1"},
        %{identifier: "http://example.com/Class2"}
      ]
      
      assert :ok = ValidateUri.verify(dsl_state_with_rdfs_classes(classes))
    end

    test "accepts RDFS classes with valid local names" do
      classes = [
        %{identifier: "Class1"},
        %{identifier: "Class_2"}
      ]
      
      assert :ok = ValidateUri.verify(dsl_state_with_rdfs_classes(classes))
    end

    test "rejects RDFS classes with invalid identifiers" do
      classes = [
        %{identifier: "ValidClass"},
        %{identifier: "Invalid Class"}
      ]
      
      assert {:error, error} = ValidateUri.verify(dsl_state_with_rdfs_classes(classes))
      assert error.message =~ "Invalid Class"
    end
  end

  describe "verify/1 with OWL classes" do
    test "accepts OWL classes with valid absolute URIs" do
      classes = [
        %{identifier: "http://example.org/OwlClass1"},
        %{identifier: "http://example.com/OwlClass2"}
      ]
      
      assert :ok = ValidateUri.verify(dsl_state_with_owl_classes(classes))
    end

    test "accepts OWL classes with valid local names" do
      classes = [
        %{identifier: "OwlClass1"},
        %{identifier: "OwlClass_2"}
      ]
      
      assert :ok = ValidateUri.verify(dsl_state_with_owl_classes(classes))
    end

    test "rejects OWL classes with invalid identifiers" do
      classes = [
        %{identifier: "ValidOwlClass"},
        %{identifier: "Invalid.OwlClass"}  # period in middle is invalid for local name
      ]
      
      assert {:error, error} = ValidateUri.verify(dsl_state_with_owl_classes(classes))
      assert error.message =~ "Invalid.OwlClass"
    end
  end
end