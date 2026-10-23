---
name: spectra-construct-tests
---

# Construct Test Suite for Go Microservice

This prompt guides the implementation of the construct-tests skill, which generates a comprehensive test suite for a Go microservice adhering to the repo's testing standard (the Testing Pyramid).

## Repo values

Read these when the skill starts. Do not store them in a file or a config key.

- Standards source: the argument `standards=<directory or URL prefix>`, or else the `standards/` directory at the repo root. Find the testing standard by its topic. When the repo has a git remote, link a standard by the absolute URL `https://<host>/<owner>/<repo>/blob/<branch>/standards/<file>`, with the values from `git remote get-url origin` and `git symbolic-ref --short refs/remotes/origin/HEAD`.
- When no standards source exists, or it holds no testing standard, print `No standards source found. Pass standards=<directory or URL prefix>.` and stop. Never guess what the standard says.
- The patterns below are Go patterns. When the repo is not a Go service, say so and stop.

## Overview

This skill orchestrates the creation of a structured test suite for a Go microservice, covering unit tests, integration-scenario tests, and smoke tests, each with their specific patterns and best practices.

## Input Parameters

- `service_name`: Name of the microservice (required)
- `package`: Package to focus on for test generation (optional, defaults to all packages)
- `test_type`: Type of tests to generate ("unit", "integration", "smoke", or "all"; default is "all")

## Usage Examples

```bash
# Generate all test types for the entire service
/skill construct-tests service_name=billing

# Generate only unit tests for a specific package
/skill construct-tests service_name=billing package=internal/domain/flow test_type=unit

# Generate integration tests for the entire service
/skill construct-tests service_name=billing test_type=integration
```

## Steps

1. Analyze Service Structure
   - Identify all packages in the service
   - Determine testable components (domain entities, application services, adapters)

2. Generate Unit Tests
   - Create test files with pattern `*_test.go` in the same package as the code
   - Implement table-driven tests with builder pattern for domain entities
   - Use manual mocks (spy pattern) for application service tests
   - Ensure all tests use `t.Parallel()` for concurrent execution
   - Implement property-based tests for critical invariants

3. Generate Integration-Scenario Tests
   - Create test files with pattern `*_integration_test.go` or `*_repo_test.go`
   - Use `//go:build integration` tag at the top of each file
   - Implement persistence tests for the service's database (the example below uses DynamoDB Local) using Testcontainers
   - Create gRPC transport tests using bufconn
   - Implement polymorphic scenario tests with separate unit and integration drivers

4. Generate Smoke Tests
   - Create test files in `test/smoke/` directory with pattern `*_test.go`
   - Use `//go:build smoke` tag at the top of each file
   - Implement critical path tests using gRPC clients
   - Use YAML payload templating for test data
   - Ensure deterministic test IDs for repeatability

5. Validate Generated Tests
   - Verify adherence to naming conventions and file structure
   - Check for proper use of build tags
   - Ensure no overlap between test layers (behaviors tested at lowest appropriate level)
   - Validate concurrency safety (use of `t.Parallel()`, avoiding global state)

6. Generate Summary
   - List all generated test files
   - Provide coverage statistics (if available)
   - Suggest areas for potential improvement or additional tests

## Test Templates

### Unit Test Template

```go
func TestEntity_Method(t *testing.T) {
    t.Parallel()

    tests := []struct {
        name    string
        builder func() *Entity
        want    string
        wantErr bool
    }{
        // Test cases here
    }

    for _, tt := range tests {
        tt := tt
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            e := tt.builder()
            got, err := e.Method()
            if (err != nil) != tt.wantErr {
                t.Errorf("Method() error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            if got != tt.want {
                t.Errorf("Method() = %v, want %v", got, tt.want)
            }
        })
    }
}
```

### Integration Test Template

```go
//go:build integration

func TestRepo_Method(t *testing.T) {
    db := testhelpers.NewTestDynamoDB(t)
    table := testhelpers.NewIsolatedTable(t, db, "TestTable")

    repo := NewRepo(db, table.Name())

    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    t.Cleanup(cancel)

    // Test implementation here
}
```

### Smoke Test Template

```go
//go:build smoke

func TestCriticalPath(t *testing.T) {
    client := testhelpers.ConnectToService(t)
    testID := DeterministicURN("smoke", t.Name(), "test")

    payload := LoadPayloadWithID(t, "test/payloads/critical-path.yaml", testID)

    resp, err := client.CriticalOperation(context.Background(), payload)
    require.NoError(t, err)
    require.NotNil(t, resp)
    assert.Equal(t, expectedStatus, resp.Status)
}
```

## Important Notes

- Always refer to the testing standard in the standards source for detailed guidelines on test structure, patterns, and best practices.
- Ensure generated tests are deterministic and do not rely on external state or random data.
- Use the builder pattern for constructing test data to improve readability and maintainability.
- Implement proper cleanup mechanisms using `t.Cleanup()` to ensure test isolation.
- For integration tests, use Testcontainers for managing dependencies like a local database. Use the dependency that the service uses.
- Smoke tests should use deterministic IDs and YAML payload templating to ensure repeatability.

Remember to validate all generated tests against the criteria outlined in the Testing Pyramid standard before considering the task complete.