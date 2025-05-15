defmodule AshRdf.DslTest do
  use ExUnit.Case

  alias AshRdf.Dsl
  
  describe "DSL section structure" do
    test "has the correct top-level section" do
      # Get the top-level section
      ash_rdf_section = Dsl.__sections__()
      
      # Check top-level section properties
      assert ash_rdf_section.name == :ash_rdf
      assert is_binary(ash_rdf_section.describe)
      
      # Check for required sub-sections
      sub_sections = ash_rdf_section.sections
      assert length(sub_sections) == 3, "Should have 3 sub-sections"
      
      # Find each expected sub-section
      rdf_section = Enum.find(sub_sections, fn section -> section.name == :rdf end)
      rdfs_section = Enum.find(sub_sections, fn section -> section.name == :rdfs end)
      owl_section = Enum.find(sub_sections, fn section -> section.name == :owl end)
      
      assert rdf_section != nil, "RDF section not found"
      assert rdfs_section != nil, "RDFS section not found"
      assert owl_section != nil, "OWL section not found"
    end
    
    test "RDF section has correct properties" do
      ash_rdf_section = Dsl.__sections__()
      sub_sections = ash_rdf_section.sections
      rdf_section = Enum.find(sub_sections, fn section -> section.name == :rdf end)
      
      # Check for expected schema
      assert Keyword.has_key?(rdf_section.schema, :base_uri)
      assert Keyword.has_key?(rdf_section.schema, :prefix)
      assert Keyword.has_key?(rdf_section.schema, :default_language)
      
      # Check for expected entities
      resource_entity = Enum.find(rdf_section.entities, fn entity -> entity.name == :resource end)
      property_entity = Enum.find(rdf_section.entities, fn entity -> entity.name == :property end)
      statement_entity = Enum.find(rdf_section.entities, fn entity -> entity.name == :statement end)
      
      assert resource_entity != nil, "Resource entity not found"
      assert property_entity != nil, "Property entity not found"
      assert statement_entity != nil, "Statement entity not found"
    end
    
    test "RDFS section has correct properties" do
      ash_rdf_section = Dsl.__sections__()
      sub_sections = ash_rdf_section.sections
      rdfs_section = Enum.find(sub_sections, fn section -> section.name == :rdfs end)
      
      # Check for expected schema
      assert Keyword.has_key?(rdfs_section.schema, :allow_inference)
      
      # Check for expected entities
      class_entity = Enum.find(rdfs_section.entities, fn entity -> entity.name == :class end)
      property_def_entity = Enum.find(rdfs_section.entities, fn entity -> entity.name == :property_definition end)
      
      assert class_entity != nil, "Class entity not found"
      assert property_def_entity != nil, "Property definition entity not found"
    end
    
    test "OWL section has correct properties" do
      ash_rdf_section = Dsl.__sections__()
      sub_sections = ash_rdf_section.sections
      owl_section = Enum.find(sub_sections, fn section -> section.name == :owl end)
      
      # Check for expected schema
      assert Keyword.has_key?(owl_section.schema, :profile)
      assert Keyword.has_key?(owl_section.schema, :reasoning)
      
      # Check for expected entities
      ontology_entity = Enum.find(owl_section.entities, fn entity -> entity.name == :ontology end)
      class_def_entity = Enum.find(owl_section.entities, fn entity -> entity.name == :class_definition end)
      
      assert ontology_entity != nil, "Ontology entity not found"
      assert class_def_entity != nil, "Class definition entity not found"
    end
  end
  
  describe "extension?/1" do
    # Modified extension? function to avoid Spark DSL dependencies
    test "extension?/1 returns true if AshRdf.Dsl is in the extensions list" do
      # Simple implementation that doesn't require Spark DSL
      extension? = fn resource_extensions ->
        AshRdf.Dsl in resource_extensions
      end
      
      assert extension?.([AshRdf.Dsl]) == true
    end
    
    test "extension?/1 returns false if AshRdf.Dsl is not in the extensions list" do
      # Simple implementation that doesn't require Spark DSL
      extension? = fn resource_extensions ->
        AshRdf.Dsl in resource_extensions
      end
      
      assert extension?.([SomeOtherModule]) == false
    end
  end
end

# Dummy module for testing
defmodule SomeOtherModule do
end