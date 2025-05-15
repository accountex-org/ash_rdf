defmodule AshRdf.Entities.Class do
  @moduledoc """
  Represents an RDFS class.
  """
  
  @typedoc "An RDFS class"
  @type t :: %__MODULE__{
    name: atom() | nil,
    uri: String.t() | nil,
    label: String.t() | nil,
    comment: String.t() | nil
  }
  
  defstruct [:name, :uri, :label, :comment]
end