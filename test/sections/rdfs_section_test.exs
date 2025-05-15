defmodule AshRdf.Sections.RdfsSectionTest do
  use ExUnit.Case

  alias AshRdf.Sections.RdfsSection
  
  describe "schema/0" do
    test "returns the expected schema options" do
      schema = RdfsSection.schema()
      
      # Verify the expected options are present
      assert Keyword.has_key?(schema, :allow_inference)
      
      # Verify option types
      assert Keyword.get(schema, :allow_inference)[:type] == :boolean
      
      # Verify default values
      assert Keyword.get(schema, :allow_inference)[:default] == true
    end
    
    test "schema options have documentation" do
      schema = RdfsSection.schema()
      
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
      entities = RdfsSection.entities()
      
      # Ensure we have the expected entities
      assert length(entities) >= 2, "Should have at least 2 entities"
      
      # Find entity by name
      class_entity = Enum.find(entities, fn entity -> entity.name == :class end)
      assert class_entity != nil, "Class entity not found"
      
      property_def_entity = Enum.find(entities, fn entity -> entity.name == :property_definition end)
      assert property_def_entity != nil, "Property definition entity not found"
    end
    
    test "class entity has expected schema" do
      entities = RdfsSection.entities()
      class_entity = Enum.find(entities, fn entity -> entity.name == :class end)
      
      # Check schema keys
      schema = class_entity.schema
      assert Keyword.has_key?(schema, :name), "Class should have name field"
      assert Keyword.has_key?(schema, :uri), "Class should have uri field"
      assert Keyword.has_key?(schema, :label), "Class should have label field"
      assert Keyword.has_key?(schema, :comment), "Class should have comment field"
    end
    
    test "property definition entity has expected schema" do
      entities = RdfsSection.entities()
      property_def_entity = Enum.find(entities, fn entity -> entity.name == :property_definition end)
      
      # Check schema keys
      schema = property_def_entity.schema
      assert Keyword.has_key?(schema, :name), "Property definition should have name field"
      assert Keyword.has_key?(schema, :uri), "Property definition should have uri field"
      assert Keyword.has_key?(schema, :domain), "Property definition should have domain field"
      assert Keyword.has_key?(schema, :range), "Property definition should have range field"
    end
    
    test "entities have documentation" do
      entities = RdfsSection.entities()
      
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
    
    test "subclass and subproperty entities exist" do
      entities = RdfsSection.entities()
      
      class_entity = Enum.find(entities, fn entity -> entity.name == :class end)
      assert class_entity != nil
      
      # Check if subclass_of is in the class entity's entities
      class_subentities = class_entity.entities || []
      subclass_entity = Enum.find(class_subentities, fn entity -> entity.name == :subclass_of end)
      assert subclass_entity != nil, "Subclass entity not found"
      
      property_def_entity = Enum.find(entities, fn entity -> entity.name == :property_definition end)
      assert property_def_entity != nil
      
      # Check if subproperty_of is in the property entity's entities
      property_subentities = property_def_entity.entities || []
      subproperty_entity = Enum.find(property_subentities, fn entity -> entity.name == :subproperty_of end)
      assert subproperty_entity != nil, "Subproperty entity not found"
    end
  end
end