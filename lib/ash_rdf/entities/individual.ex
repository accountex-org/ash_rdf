defmodule AshRdf.Entities.Individual do
  @moduledoc """
  Represents an OWL2 individual.
  """
  
  @typedoc "An OWL2 individual"
  @type t :: %__MODULE__{
    name: atom() | nil,
    uri: String.t() | nil,
    types: [String.t() | atom()] | nil,
    label: String.t() | nil,
    comment: String.t() | nil
  }
  
  defstruct [:name, :uri, :types, :label, :comment]
end