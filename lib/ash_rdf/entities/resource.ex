defmodule AshRdf.Entities.Resource do
  @moduledoc """
  Represents an RDF resource (subject).
  """
  
  @typedoc "An RDF resource"
  @type t :: %__MODULE__{
    uri: String.t() | nil,
    blank_node: boolean() | nil,
    blank_node_id: String.t() | nil
  }
  
  defstruct [:uri, :blank_node, :blank_node_id]
end