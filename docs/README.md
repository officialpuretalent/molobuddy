# Molo Design Documentation

- **Status:** Active
- **Owner:** Product and engineering
- **Last updated:** 19 August 2026

This directory contains designs that can be developed and reviewed independently. Each design area has its own directory, index and decision boundary.

## Design catalogue

| Design area | Directory | Status | Purpose |
|---|---|---|---|
| Product foundation | [`product/`](product/) | Active | Brand, shared vocabulary and system-level architecture |
| API design | [`api_design/`](api_design/) | Active | External and application endpoint contracts |
| App design | [`app_design/`](app_design/) | Foundation v1.0 | Flutter MVVM, Riverpod, responsive multiplatform and dependency foundation |
| Backend design | [`backend_design/`](backend_design/) | Active | Runtime, DDD boundaries, authentication and source structure |
| Data design | [`data_design/`](data_design/) | Reserved | Domain records, relationships, invariants, indexes, retention and migrations |

## Directory rule

Create a dedicated design directory when a concern can be specified, reviewed and versioned independently. Examples include API design, data design, security design, interaction design and connector design.

Each design directory must contain:

1. a `README.md` defining shared rules and the source-of-truth boundary;
2. one Markdown file per independently owned domain or design unit;
3. links to related architecture and vocabulary decisions;
4. explicit status, version and unresolved decisions;
5. contracts and acceptance criteria that can be tested.

Do not mix implementation notes into a design contract unless they constrain observable behaviour.

## Project-wide sources

- [System architecture](product/system_architecture.md)
- [Product glossary](product/glossary.md)
- [Molo brand platform](product/brand_platform.md)
- [Local development runbook](local_development.md)
