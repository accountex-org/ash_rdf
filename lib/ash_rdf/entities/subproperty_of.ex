defmodule AshRdf.Entities.SubpropertyOf do
  @moduledoc """
  Represents an RDFS subproperty relationship.
  """
  
  @typedoc "An RDFS subproperty relationship"
  @type t :: %__MODULE__{
    property_uri: String.t() | atom() | nil
  }
  
  defstruct [:property_uri]
end