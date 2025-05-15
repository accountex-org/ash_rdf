defmodule AshRdf.Entities.EquivalentClass do
  @moduledoc """
  Represents an OWL2 equivalent class relationship.
  """
  
  @typedoc "An OWL2 equivalent class relationship"
  @type t :: %__MODULE__{
    class_uri: String.t() | atom() | nil
  }
  
  defstruct [:class_uri]
end