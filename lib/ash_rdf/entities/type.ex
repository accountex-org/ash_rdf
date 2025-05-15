defmodule AshRdf.Entities.Type do
  @moduledoc """
  Represents an OWL2 type declaration.
  """
  
  @typedoc "An OWL2 type declaration"
  @type t :: %__MODULE__{
    class_uri: String.t() | atom() | nil
  }
  
  defstruct [:class_uri]
end