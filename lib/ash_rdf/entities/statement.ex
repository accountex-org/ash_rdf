defmodule AshRdf.Entities.Statement do
  @moduledoc """
  Represents an RDF statement (triple).
  """
  
  @typedoc "An RDF statement (triple)"
  @type t :: %__MODULE__{
    subject: String.t() | nil,
    predicate: String.t() | nil,
    object: String.t() | atom() | number() | boolean() | nil,
    datatype: String.t() | nil,
    language: String.t() | nil
  }
  
  defstruct [:subject, :predicate, :object, :datatype, :language]
end