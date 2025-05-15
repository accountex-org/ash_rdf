defmodule AshRdf.Sections.RdfSectionTest do
  use ExUnit.Case

  alias AshRdf.Sections.RdfSection
  
  describe "schema/0" do
    test "returns the expected schema options" do
      schema = RdfSection.schema()
      
      # Verify the expected options are present
      assert Keyword.has_key?(schema, :base_uri)
      assert Keyword.has_key?(schema, :prefix)
      assert Keyword.has_key?(schema, :default_language)
      
      # Verify option types
      assert Keyword.get(schema, :base_uri)[:type] == :string
      assert Keyword.get(schema, :prefix)[:type] == :string
      assert Keyword.get(schema, :default_language)[:type] == :string
      
      # Verify required fields
      assert Keyword.get(schema, :base_uri)[:required] == true
      
      # Verify default values
      assert Keyword.get(schema, :default_language)[:default] == "en"
    end
    
    test "schema options have documentation" do
      schema = RdfSection.schema()
      
      # All options should have documentation
      for {key, option} <- schema do
        assert Keyword.has_key?(option, :doc), "Option #{key} is missing documentation"
        assert is_binary(Keyword.get(option, :doc)), "Option #{key} has non-string documentation"
        assert String.length(Keyword.get(option, :doc)) > 0, "Option #{key} has empty documentation"
      end
    end
  end
  
  describe "entities/0" do
    test "returns the expected entities" do
      entities = RdfSection.entities()
      
      # Ensure we have the expected number of entities
      assert length(entities) >= 3, "Should have at least 3 entities"
      
      # Find entity by name
      resource_entity = Enum.find(entities, fn entity -> entity.name == :resource end)
      assert resource_entity != nil, "Resource entity not found"
      
      property_entity = Enum.find(entities, fn entity -> entity.name == :property end)
      assert property_entity != nil, "Property entity not found"
      
      statement_entity = Enum.find(entities, fn entity -> entity.name == :statement end)
      assert statement_entity != nil, "Statement entity not found"
    end
    
    test "resource entity has expected schema" do
      entities = RdfSection.entities()
      resource_entity = Enum.find(entities, fn entity -> entity.name == :resource end)
      
      # Check schema keys
      schema = resource_entity.schema
      assert Keyword.has_key?(schema, :uri), "Resource should have uri field"
      assert Keyword.has_key?(schema, :blank_node), "Resource should have blank_node field"
      assert Keyword.has_key?(schema, :blank_node_id), "Resource should have blank_node_id field"
    end
    
    test "entities have documentation" do
      entities = RdfSection.entities()
      
      for entity <- entities do
        assert is_binary(entity.describe), "Entity #{entity.name} missing description"
        assert String.length(entity.describe) > 0, "Entity #{entity.name} has empty description"
        
        # Check schema option documentation
        for {key, option} <- entity.schema do
          assert Keyword.has_key?(option, :doc), "Option #{key} in entity #{entity.name} missing documentation"
          assert is_binary(Keyword.get(option, :doc)), "Option #{key} in entity #{entity.name} has non-string documentation"
          assert String.length(Keyword.get(option, :doc)) > 0, "Option #{key} in entity #{entity.name} has empty documentation"
        end
      end
    end
  end
end