defmodule AshRdf.Entities.PropertyAssertion do
  @moduledoc """
  Represents an OWL2 property assertion for an individual.
  """
  
  @typedoc "An OWL2 property assertion for an individual"
  @type t :: %__MODULE__{
    property: String.t() | atom() | nil,
    value: any() | nil,
    datatype: String.t() | nil,
    language: String.t() | nil
  }
  
  defstruct [:property, :value, :datatype, :language]
end