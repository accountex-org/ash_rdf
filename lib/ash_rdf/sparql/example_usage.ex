defmodule AshRdf.Sparql.ExampleUsage do
  @moduledoc """
  Example of using the SPARQL Data Layer with Ash.
  
  This module provides annotated examples of configuring and using the SPARQL
  data layer with Ash resources.
  """

  @doc """
  Example resource definition using SPARQL data layer.
  
  ```elixir
  defmodule MyApp.Resources.Person do
    use Ash.Resource,
      domain: MyApp.Domain,
      data_layer: AshRdf.Sparql.DataLayer
    
    # Standard Ash attributes and identifiers
    attributes do
      uuid_primary_key :id
      
      attribute :name, :string do
        default "Anonymous"
      end
      
      attribute :email, :string
      attribute :age, :integer
      attribute :bio, :string
    end
    
    # RDF section defines base URI and prefixes
    ash_rdf do
      rdf do
        base_uri "http://example.org/people/"
        prefix "people"
        
        namespaces do
          prefix "foaf", "http://xmlns.com/foaf/0.1/"
          prefix "schema", "http://schema.org/"
          prefix "xsd", "http://www.w3.org/2001/XMLSchema#"
        end
      end
      
      # RDFS section defines classes and properties
      rdfs do
        class name: :person do
          label "Person"
          comment "A human being"
        end
      end
      
      # SPARQL section configures the data layer
      sparql do
        # Connection to SPARQL endpoint
        endpoint do
          endpoint "https://dbpedia.org/sparql"
          default_graph "http://dbpedia.org"
          
          # Optional authentication
          credentials %{
            auth_method: :basic,
            username: "username",
            password: "password"
          }
          
          # Additional client options
          client_options [
            timeout: 60_000,
            follow_redirects: true
          ]
        end
        
        # Mapping resource attributes to RDF predicates
        mapping do
          # Optional override of class/base_uri from rdfs/rdf sections
          class "http://xmlns.com/foaf/0.1/Person"
          
          attributes do
            map :name, to: "http://xmlns.com/foaf/0.1/name"
            map :email, to: "http://xmlns.com/foaf/0.1/mbox"
            map :age, to: "http://xmlns.com/foaf/0.1/age",
                      datatype: "http://www.w3.org/2001/XMLSchema#integer"
            map :bio, to: "http://xmlns.com/foaf/0.1/bio",
                      language: "en"
          end
        end
        
        # Query optimization options
        options do
          fetch_size 500
          timeout 30_000
          cache true
          cache_ttl 300_000  # 5 minutes
          retry true
          retry_count 3
          retry_delay 1000
        end
      end
    end
    
    # Actions for the resource
    actions do
      defaults [:create, :read, :update, :destroy]
      
      read :by_name do
        argument :name, :string
        filter expr(name == ^arg.name)
      end
    end
    
    # Relations to other resources
    relationships do
      belongs_to :organization, MyApp.Resources.Organization
      
      has_many :authored_papers, MyApp.Resources.Paper do
        destination_attribute :author_id
      end
    end
  end
  ```
  """
  
  @doc """
  Example usage of the resource with SPARQL data layer.
  
  ```elixir
  # Basic CRUD operations
  
  # Create a new person
  {:ok, person} = 
    MyApp.Resources.Person
    |> Ash.Changeset.for_create(:create, %{
      name: "John Doe",
      email: "john@example.com",
      age: 30
    })
    |> MyApp.Domain.create()
  
  # Read a person by ID
  {:ok, person} = MyApp.Resources.Person |> MyApp.Domain.get("123e4567-e89b-12d3-a456-426614174000")
  
  # Read with custom action
  {:ok, person} = MyApp.Resources.Person |> MyApp.Domain.get_by_name(%{name: "John Doe"})
  
  # Query with filters
  people = 
    MyApp.Resources.Person
    |> Ash.Query.filter(age > 25)
    |> Ash.Query.sort(name: :asc)
    |> Ash.Query.limit(10)
    |> MyApp.Domain.read!()
  
  # Update a person
  {:ok, updated_person} = 
    person
    |> Ash.Changeset.for_update(:update, %{
      age: 31,
      bio: "Software developer and author"
    })
    |> MyApp.Domain.update()
  
  # Delete a person
  :ok = MyApp.Domain.destroy(person)
  
  # Loading relationships
  {:ok, person_with_papers} = 
    person
    |> Ash.Query.load(:authored_papers)
    |> MyApp.Domain.read()
  ```
  """
  
  @doc """
  Example configuration for mix.exs.
  
  ```elixir
  defp deps do
    [
      {:ash, "~> 3.0"},
      {:ash_rdf, "~> 0.1"},
      {:tesla, "~> 1.4"},
      {:jason, "~> 1.2"},
      {:sweet_xml, "~> 0.7"}
    ]
  end
  ```
  """
end