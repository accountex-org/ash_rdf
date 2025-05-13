defmodule AshRdf.Verifiers.ValidateUriIntegrationTest do
  use ExUnit.Case

  describe "URI validation in resources" do
    test "accepts valid resource with proper base_uri" do
      defmodule ValidTest do
        use Ash.Resource,
          extensions: [AshRdf]

        attributes do
          uuid_primary_key :id
        end

        rdf do
          base_uri "http://example.org/resource/"
        end
      end

      # No exception means verification passed
      assert ValidTest.__struct__
    end

    test "rejects resource with invalid base_uri (no schema)" do
      assert_raise Spark.Error.DslError, ~r/Base URI 'example.org\/resource\/' must be an absolute URI/, fn ->
        defmodule InvalidBaseUriTest do
          use Ash.Resource,
            extensions: [AshRdf]

          attributes do
            uuid_primary_key :id
          end

          rdf do
            base_uri "example.org/resource/"  # Missing http:// prefix
          end
        end
      end
    end

    test "rejects resource with invalid base_uri (no trailing delimiter)" do
      assert_raise Spark.Error.DslError, ~r/Base URI 'http:\/\/example.org\/resource' should end with '\/' or '#'/, fn ->
        defmodule InvalidBaseUriEndingTest do
          use Ash.Resource,
            extensions: [AshRdf]

          attributes do
            uuid_primary_key :id
          end

          rdf do
            base_uri "http://example.org/resource"  # Missing trailing / or #
          end
        end
      end
    end

    test "rejects resource with invalid resource identifier" do
      assert_raise Spark.Error.DslError, ~r/'invalid resource id' is neither a valid absolute URI nor a valid local name/, fn ->
        defmodule InvalidResourceIdTest do
          use Ash.Resource,
            extensions: [AshRdf]

          attributes do
            uuid_primary_key :id
          end

          rdf do
            base_uri "http://example.org/resource/"
          end
          
          rdf.resource do
            identifier "invalid resource id"  # Contains spaces
          end
        end
      end
    end

    test "accepts resource with valid RDFS class" do
      defmodule ValidRdfsTest do
        use Ash.Resource,
          extensions: [AshRdf]

        attributes do
          uuid_primary_key :id
        end

        rdf do
          base_uri "http://example.org/resource/"
        end
        
        rdfs.class do
          identifier "Person"
        end
      end

      # No exception means verification passed
      assert ValidRdfsTest.__struct__
    end

    test "rejects resource with invalid RDFS class identifier" do
      assert_raise Spark.Error.DslError, ~r/'Person Class' is neither a valid absolute URI nor a valid local name/, fn ->
        defmodule InvalidRdfsTest do
          use Ash.Resource,
            extensions: [AshRdf]

          attributes do
            uuid_primary_key :id
          end

          rdf do
            base_uri "http://example.org/resource/"
          end
          
          rdfs.class do
            identifier "Person Class"  # Contains spaces
          end
        end
      end
    end
  end
end