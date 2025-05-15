defmodule AshRdf.Entities.Restriction do
  @moduledoc """
  Represents an OWL2 property restriction.
  """
  
  @typedoc "An OWL2 property restriction"
  @type t :: %__MODULE__{
    name: atom() | nil,
    on_property: String.t() | atom() | nil,
    some_values_from: String.t() | atom() | nil,
    all_values_from: String.t() | atom() | nil,
    value: any() | nil,
    min_cardinality: integer() | nil,
    max_cardinality: integer() | nil,
    cardinality: integer() | nil,
    has_self: boolean() | nil
  }
  
  defstruct [
    :name,
    :on_property,
    :some_values_from,
    :all_values_from,
    :value,
    :min_cardinality,
    :max_cardinality,
    :cardinality,
    :has_self
  ]
end