defmodule AshRdf.Entities.Import do
  @moduledoc """
  Represents an OWL2 ontology import.
  """
  
  @typedoc "An OWL2 ontology import"
  @type t :: %__MODULE__{
    uri: String.t() | nil
  }
  
  defstruct [:uri]
end