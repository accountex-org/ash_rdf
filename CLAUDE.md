# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AshRdf is an Elixir package in early development stages that appears intended to provide RDF (Resource Description Framework) functionality for the Ash Framework. The project currently contains only a skeleton structure with placeholder functionality.

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
# Generate documentation (requires ex_doc to be added to dependencies first)
mix docs
```

## Architecture

The project is in the very early stages of development, with only a minimal structure:

- Main module `AshRdf` in `lib/ash_rdf.ex` with placeholder functionality
- Basic test suite in `test/ash_rdf_test.exs`

The project likely aims to integrate with the Ash Framework to provide RDF capabilities, but no implementation has been started yet.

## Development Environment

- Requires Elixir ~> 1.18
- Uses `igniter` (~> 0.5) for development tooling
- Protocol consolidation is disabled in development environment