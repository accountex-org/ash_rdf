defmodule AshRdf.Entities.Ontology do
  @moduledoc """
  Represents an OWL2 ontology.
  """
  
  @typedoc "An OWL2 ontology"
  @type t :: %__MODULE__{
    uri: String.t() | nil,
    version: String.t() | nil,
    label: String.t() | nil,
    comment: String.t() | nil,
    imports: [String.t()] | nil
  }
  
  defstruct [:uri, :version, :label, :comment, :imports]
end