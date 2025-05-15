defmodule AshRdf.Entities.SubclassOf do
  @moduledoc """
  Represents an RDFS subclass relationship.
  """
  
  @typedoc "An RDFS subclass relationship"
  @type t :: %__MODULE__{
    class_uri: String.t() | atom() | nil
  }
  
  defstruct [:class_uri]
end