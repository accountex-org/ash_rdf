defmodule AshRdf.Entities.ClassDefinition do
  @moduledoc """
  Represents an OWL2 class definition.
  """
  
  @typedoc "An OWL2 class definition"
  @type t :: %__MODULE__{
    name: atom() | nil,
    uri: String.t() | nil,
    label: String.t() | nil,
    comment: String.t() | nil,
    deprecated: boolean() | nil
  }
  
  defstruct [:name, :uri, :label, :comment, :deprecated]
end