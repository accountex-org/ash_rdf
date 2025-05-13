defmodule AshRdf.Test.Support.ValidResource do
  @moduledoc false
  use Ash.Resource,
    extensions: [AshRdf]

  attributes do
    uuid_primary_key :id
    attribute :name, :string
  end

  rdf do
    base_uri "http://example.org/resource/"
    prefix "test"
  end
end

defmodule AshRdf.Test.Support.InvalidBaseUriResource do
  @moduledoc false
  use Ash.Resource,
    extensions: [AshRdf]

  attributes do
    uuid_primary_key :id
    attribute :name, :string
  end

  rdf do
    base_uri "example.org/resource/"  # Missing http:// prefix
    prefix "test"
  end
end

defmodule AshRdf.Test.Support.InvalidBaseUriEndingResource do
  @moduledoc false
  use Ash.Resource,
    extensions: [AshRdf]

  attributes do
    uuid_primary_key :id
    attribute :name, :string
  end

  rdf do
    base_uri "http://example.org/resource"  # Missing trailing / or #
    prefix "test"
  end
end

defmodule AshRdf.Test.Support.InvalidResourceIdResource do
  @moduledoc false
  use Ash.Resource,
    extensions: [AshRdf]

  attributes do
    uuid_primary_key :id
    attribute :name, :string
  end

  rdf do
    base_uri "http://example.org/resource/"
    prefix "test"
  end

  rdf.resource do
    identifier "invalid resource id"  # Contains spaces
  end
end

defmodule AshRdf.Test.Support.ValidRdfsResource do
  @moduledoc false
  use Ash.Resource,
    extensions: [AshRdf]

  attributes do
    uuid_primary_key :id
    attribute :name, :string
  end

  rdf do
    base_uri "http://example.org/resource/"
    prefix "test"
  end

  rdfs.class do
    identifier "Person"
  end
end

defmodule AshRdf.Test.Support.InvalidRdfsResource do
  @moduledoc false
  use Ash.Resource,
    extensions: [AshRdf]

  attributes do
    uuid_primary_key :id
    attribute :name, :string
  end

  rdf do
    base_uri "http://example.org/resource/"
    prefix "test"
  end

  rdfs.class do
    identifier "Person Class"  # Contains spaces
  end
end