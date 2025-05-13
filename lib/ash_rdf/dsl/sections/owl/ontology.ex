defmodule AshRdf.Dsl.Sections.Owl.Ontology do
  @moduledoc """
  DSL section for defining OWL ontologies.
  
  An ontology in OWL2 is a collection of axioms that together
  describe a domain of interest.
  """

  @section %Spark.Dsl.Section{
    name: :ontology,
    describe: "Defines an OWL2 ontology",
    schema: [
      uri: [
        type: :string,
        required: true,
        doc: "The URI for this ontology"
      ],
      version: [
        type: :string,
        doc: "The version of this ontology"
      ],
      prefix: [
        type: :string,
        doc: "The preferred prefix for this ontology"
      ],
      label: [
        type: :string,
        doc: "Human-readable label for the ontology"
      ],
      comment: [
        type: :string,
        doc: "Human-readable description of the ontology"
      ],
      prior_version: [
        type: :string,
        doc: "URI of the prior version of this ontology"
      ],
      backward_compatible_with: [
        type: :string,
        doc: "URI of a prior version that this version is compatible with"
      ],
      incompatible_with: [
        type: :string,
        doc: "URI of a prior version that this version is incompatible with"
      ]
    ],
    sections: [
      AshRdf.Dsl.Sections.Owl.Import.build()
    ]
  }
  
  @doc """
  Returns the OWL ontology DSL section.
  """
  def build, do: @section
end