# AshRdf

AshRdf is an extension for the [Ash Framework](https://ash-hq.org) that provides capabilities for working with RDF (Resource Description Framework) data and ontologies.

## Features

- **RDF Core Support**: Represent and manipulate RDF triples (subject-predicate-object statements)
- **RDFS Extensions**: Define classes, properties, domains, ranges, and hierarchical relationships
- **OWL2 Support**: Create sophisticated ontologies with complex class definitions, property characteristics, and logical constraints
- **Semantic Data Integration**: Map Ash resources to RDF/OWL representations
- **Serialization**: Export data in Turtle, N-Triples, and JSON-LD formats

## Installation

Add `ash_rdf` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_rdf, "~> 0.1.0"}
  ]
end
```

## Usage

### Basic Setup

Define an Ash resource with AshRdf extensions:

```elixir
defmodule MyApp.People.Person do
  use Ash.Resource,
    extensions: [AshRdf]
    
  rdf do
    base_uri "http://example.org/people/"
    prefix "people"
  end
  
  # Define attributes, relationships, etc.
end
```

### RDF Core Functionality

Create RDF statements and graphs:

```elixir
# Create an RDF graph
graph = AshRdf.Rdf.new_graph()

# Add statements to the graph
graph = graph
|> AshRdf.Rdf.Graph.add("http://example.org/john", "http://example.org/name", "John Doe")
|> AshRdf.Rdf.Graph.add("http://example.org/john", "http://example.org/age", 30, datatype: "http://www.w3.org/2001/XMLSchema#integer")

# Convert to Turtle format
turtle_string = AshRdf.Rdf.Graph.to_turtle(graph)
```

Convert Ash resources to RDF:

```elixir
# Convert a resource instance to RDF
person = MyApp.People.get_person_by_id!(1)
statements = AshRdf.Rdf.resource_to_rdf(MyApp.People.Person, person)

# Convert to a graph
graph = AshRdf.Rdf.resource_to_graph(MyApp.People.Person, person)

# Export to Turtle format
turtle = AshRdf.Rdf.resource_to_turtle(MyApp.People.Person, person)
```

### RDFS Functionality

Define classes and properties with RDFS semantics:

```elixir
defmodule MyApp.People.Person do
  use Ash.Resource,
    extensions: [AshRdf]
    
  rdf do
    base_uri "http://example.org/people/"
    prefix "people"
  end
  
  rdfs do
    class :person do
      label "Person"
      comment "A human being"
    end
    
    property :name do
      uri "http://example.org/ontology/name"
      domain "http://example.org/people/Person"
      range "http://www.w3.org/2001/XMLSchema#string"
      label "Name"
      comment "The full name of a person"
    end
  end
  
  # Define attributes, relationships, etc.
end
```

### OWL Functionality

Define rich ontologies with OWL:

```elixir
defmodule MyApp.Ontology do
  use Ash.Resource,
    extensions: [AshRdf]
    
  rdf do
    base_uri "http://example.org/ontology/"
    prefix "onto"
  end
  
  owl do
    ontology do
      uri "http://example.org/ontology/"
      version "1.0.0"
      label "My Application Ontology"
    end
    
    class :person do
      label "Person"
      comment "A human being"
    end
    
    class :employee do
      label "Employee"
      comment "A person employed by an organization"
      
      subclass_of do
        class_uri "http://example.org/ontology/Person"
      end
    end
    
    property :works_for do
      type :object_property
      domain "http://example.org/ontology/Employee"
      range "http://example.org/ontology/Organization"
      label "Works For"
      functional true
    end
    
    restriction :full_time_employee do
      on_property "http://example.org/ontology/hoursPerWeek"
      min_cardinality 40
    end
  end
end

# Get OWL definitions as a graph
graph = AshRdf.Owl.resource_to_graph(MyApp.Ontology)

# Export to Turtle format
turtle = AshRdf.Owl.to_turtle(MyApp.Ontology)
```

## Documentation

For full documentation, see the [HexDocs](https://hexdocs.pm/ash_rdf).

## License

This project is licensed under the MIT License - see the LICENSE file for details.