defmodule AshRdf.Dsl.Sections.Rdfs.Class do
  @moduledoc """
  DSL section for defining RDFS classes.
  
  Classes in RDFS represent categories or types of resources.
  """

  use Spark.Dsl.Section

  dsl_section do
    section_name(:class)
    desc("Defines an RDFS class")
    
    option :name, :atom,
      required: true,
      doc: "The name of the class"
      
    option :uri, :string,
      doc: "The URI for this class (will be combined with base_uri if relative)"
      
    has_many :subclass_of, AshRdf.Dsl.Sections.Rdfs.SubclassOf,
      default: [],
      doc: "Classes that this class is a subclass of"
      
    option :label, :string,
      doc: "Human-readable label for the class"
      
    option :comment, :string,
      doc: "Human-readable description of the class"
      
    option :see_also, :string,
      doc: "Related resource to this class"
  end
end