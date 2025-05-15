defmodule AshRdf.Entities.DisjointClass do
  @moduledoc """
  Represents an OWL2 disjoint class relationship.
  """
  
  @typedoc "An OWL2 disjoint class relationship"
  @type t :: %__MODULE__{
    class_uri: String.t() | atom() | nil
  }
  
  defstruct [:class_uri]
end