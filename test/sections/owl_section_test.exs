defmodule AshRdf.Sections.OwlSectionTest do
  use ExUnit.Case

  alias AshRdf.Sections.OwlSection
  
  describe "schema/0" do
    test "returns the expected schema options" do
      schema = OwlSection.schema()
      
      # Verify the expected options are present
      assert Keyword.has_key?(schema, :profile)
      assert Keyword.has_key?(schema, :reasoning)
      
      # Verify option types
      assert Keyword.get(schema, :profile)[:type] == {:one_of, [:rl, :el, :ql, :dl, :full]}
      assert Keyword.get(schema, :reasoning)[:type] == :boolean
      
      # Verify default values
      assert Keyword.get(schema, :profile)[:default] == :dl
      assert Keyword.get(schema, :reasoning)[:default] == true
    end
    
    test "schema options have documentation" do
      schema = OwlSection.schema()
      
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
      entities = OwlSection.entities()
      
      # Ensure we have the expected entities
      assert length(entities) >= 5, "Should have at least 5 entities"
      
      # Find entity by name
      ontology_entity = Enum.find(entities, fn entity -> entity.name == :ontology end)
      assert ontology_entity != nil, "Ontology entity not found"
      
      class_def_entity = Enum.find(entities, fn entity -> entity.name == :class_definition end)
      assert class_def_entity != nil, "Class definition entity not found"
      
      property_def_entity = Enum.find(entities, fn entity -> entity.name == :property_definition end)
      assert property_def_entity != nil, "Property definition entity not found"
      
      individual_entity = Enum.find(entities, fn entity -> entity.name == :individual end)
      assert individual_entity != nil, "Individual entity not found"
      
      restriction_entity = Enum.find(entities, fn entity -> entity.name == :restriction end)
      assert restriction_entity != nil, "Restriction entity not found"
    end
    
    test "class definition entity has expected schema" do
      entities = OwlSection.entities()
      class_def_entity = Enum.find(entities, fn entity -> entity.name == :class_definition end)
      
      # Check schema keys
      schema = class_def_entity.schema
      assert Keyword.has_key?(schema, :name), "Class definition should have name field"
      assert Keyword.has_key?(schema, :uri), "Class definition should have uri field"
      assert Keyword.has_key?(schema, :label), "Class definition should have label field"
      assert Keyword.has_key?(schema, :comment), "Class definition should have comment field"
      assert Keyword.has_key?(schema, :deprecated), "Class definition should have deprecated field"
    end
    
    test "property definition entity has expected schema" do
      entities = OwlSection.entities()
      property_def_entity = Enum.find(entities, fn entity -> entity.name == :property_definition end)
      
      # Check schema keys
      schema = property_def_entity.schema
      assert Keyword.has_key?(schema, :name), "Property definition should have name field"
      assert Keyword.has_key?(schema, :uri), "Property definition should have uri field"
      assert Keyword.has_key?(schema, :type), "Property definition should have type field"
      assert Keyword.has_key?(schema, :domain), "Property definition should have domain field"
      assert Keyword.has_key?(schema, :range), "Property definition should have range field"
    end
    
    test "ontology entity has expected schema" do
      entities = OwlSection.entities()
      ontology_entity = Enum.find(entities, fn entity -> entity.name == :ontology end)
      
      # Check schema keys
      schema = ontology_entity.schema
      assert Keyword.has_key?(schema, :uri), "Ontology should have uri field"
      assert Keyword.has_key?(schema, :version), "Ontology should have version field"
      assert Keyword.has_key?(schema, :label), "Ontology should have label field"
    end
    
    test "entities have documentation" do
      entities = OwlSection.entities()
      
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
    
    test "class definition has subentities" do
      entities = OwlSection.entities()
      class_def_entity = Enum.find(entities, fn entity -> entity.name == :class_definition end)
      
      # Check if equivalent_class and disjoint_class are in the class entity's entities
      class_subentities = class_def_entity.entities || []
      
      equivalent_class_entity = Enum.find(class_subentities, fn entity -> entity.name == :equivalent_class end)
      assert equivalent_class_entity != nil, "Equivalent class entity not found"
      
      disjoint_class_entity = Enum.find(class_subentities, fn entity -> entity.name == :disjoint_class end)
      assert disjoint_class_entity != nil, "Disjoint class entity not found"
    end
    
    test "restriction entity has expected schema" do
      entities = OwlSection.entities()
      restriction_entity = Enum.find(entities, fn entity -> entity.name == :restriction end)
      
      # Check schema keys
      schema = restriction_entity.schema
      assert Keyword.has_key?(schema, :name), "Restriction should have name field"
      assert Keyword.has_key?(schema, :on_property), "Restriction should have on_property field"
      
      # Check if it has at least one of the restriction types
      has_restriction_type = Keyword.has_key?(schema, :some_values_from) ||
                            Keyword.has_key?(schema, :all_values_from) ||
                            Keyword.has_key?(schema, :min_cardinality) ||
                            Keyword.has_key?(schema, :max_cardinality) ||
                            Keyword.has_key?(schema, :cardinality)
      
      assert has_restriction_type, "Restriction should have at least one restriction type field"
    end
  end
end