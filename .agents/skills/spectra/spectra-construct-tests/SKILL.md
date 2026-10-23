---
name: spectra-construct-tests
title: Construct Test Suite for Go Microservice
version: 1.0
description: |
  Use this skill to generate a comprehensive test suite for a Go microservice
  following the Testing Pyramid standard. It orchestrates the creation of unit,
  integration-scenario, and smoke tests adhering to best practices and conventions.
---

Needs: a Go service repo, `make test` and `make smoke` (or equivalent commands), and a standards source with a testing standard.

Prompt files are in `.agents/skills/spectra/`. Each item below gives the path.

Load and execute in order:

1. `.agents/skills/spectra/spectra-construct-tests/construct-tests.prompt.md`
