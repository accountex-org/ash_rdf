# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AshRdf is an Elixir extension for the Ash Framework that provides capabilities for working with RDF (Resource Description Framework) data and ontologies. The project is in early development (v0.1.0) with basic functionality implemented but still needs more work.

AshRdf implements support for:
- **RDF Core**: Working with resources, properties, literals, and statements (triples)
- **RDFS (RDF Schema)**: Classes, subclasses, property definitions, domains, and ranges
- **OWL2 (Web Ontology Language)**: Complex class relationships, property characteristics, and logical constraints
- **Serialization**: Export data in Turtle, N-Triples, and JSON-LD formats
- **Integration**: Map Ash resources to RDF/OWL representations

## Commands

### Setup and Dependencies
```bash
# Install dependencies
mix deps.get
```

### Building
```bash
# Compile the project
mix compile
```

### Testing
```bash
# Run all tests
mix test

# Run a specific test file
mix test test/file_path.exs

# Run a specific test (line number based)
mix test test/file_path.exs:line_number
```

### Documentation
```bash
# Generate documentation
mix docs
```

## Architecture

The project is structured around three main components:

1. **Core Module**: `AshRdf` (`lib/ash_rdf.ex`) - Uses Spark.Dsl.Extension with transformers and verifiers
2. **DSL Definition**: `AshRdf.Dsl` (`lib/ash_rdf/dsl.ex`) - Provides DSL sections for RDF, RDFS, and OWL
3. **Main Components**:
   - `AshRdf.Rdf` - Core RDF functionality (graphs, statements, resources, URIs)
   - `AshRdf.Rdfs` - RDFS extensions (classes, properties, hierarchies)
   - `AshRdf.Owl` - OWL features (ontologies, restrictions, class expressions)

Implementation includes:
- Transformers for validation (`AshRdf.Transformers.ValidateRdfStructure`)
- Verifiers for URI validation (`AshRdf.Verifiers.ValidateUri`)
- Serialization/deserialization for different RDF formats

## Development Environment

- Requires Elixir ~> 1.18
- Dependencies:
  - ash (~> 3.0)
  - spark (~> 2.0)
  - igniter (~> 0.5) for development tooling
  - ex_doc (~> 0.27) for documentation
- Protocol consolidation is disabled in development environment