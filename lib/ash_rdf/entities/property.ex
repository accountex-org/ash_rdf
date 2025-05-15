defmodule AshRdf.Entities.Property do
  @moduledoc """
  Represents an RDF property (predicate).
  """
  
  @typedoc "An RDF property"
  @type t :: %__MODULE__{
    uri: String.t() | nil,
    datatype: String.t() | nil
  }
  
  defstruct [:uri, :datatype]
end