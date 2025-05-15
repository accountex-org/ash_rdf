defmodule AshRdf.Entities.Identifier do
  @moduledoc """
  Represents an identifier for a resource or property.
  """
  
  @typedoc "An identifier for a resource or property"
  @type t :: %__MODULE__{
    name: String.t() | nil
  }
  
  defstruct [:name]
end