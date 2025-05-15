defmodule AshRdf.Entities.PropertyDefinition do
  @moduledoc """
  Represents an RDFS property definition.
  """
  
  @typedoc "An RDFS property definition"
  @type t :: %__MODULE__{
    name: atom() | nil,
    uri: String.t() | nil,
    domain: String.t() | atom() | nil,
    range: String.t() | atom() | nil,
    label: String.t() | nil,
    comment: String.t() | nil
  }
  
  defstruct [:name, :uri, :domain, :range, :label, :comment]
end