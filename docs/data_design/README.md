# Molo Data Design

- **Status:** Identity and access drafted; remaining domains reserved for design
- **Owner:** Product and engineering
- **Last updated:** 20 August 2026

This directory will hold Molo's persistence and information-model contracts. It is deliberately separate from API design: an API contract describes what callers can observe and request, while a data design describes how durable business truth is represented and protected.

## Planned domain files

Use one Markdown file per domain:

- `identity_access.md`
- `practices.md`
- `taxpayers.md`
- `tax_work.md`
- `documents.md`
- `workflows.md`
- `notifications.md`
- `connectors.md`
- `intelligence.md`
- `audit.md`

## Every data-design file must define

- canonical records and identifiers;
- ownership and regional placement;
- relationships and cardinality;
- invariants and state transitions;
- sensitive-field classification;
- indexes and supported query shapes;
- retention and deletion behaviour;
- event and projection implications;
- migration and compatibility rules;
- acceptance tests.

The current high-level model remains in the [system architecture](../product/system_architecture.md) until each domain is promoted into this directory.
