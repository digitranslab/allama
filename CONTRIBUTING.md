# Contributing to Allama

We welcome contributions from the community. Whether you're adding integrations, fixing bugs, or improving documentation, your work helps make security automation accessible to everyone.

Join us on [Discord](https://discord.gg/2mK6h9rp) in the `#contributors` channel.

## What You Can Contribute

- Action Templates (YAML-based integration recipes)
- Python integrations (client-based integrations using boto3, falconpy, etc.)
- Inline functions for the expressions engine
- Documentation improvements
- Bug fixes

## Getting Started

### Prerequisites

- Python 3.12+
- Docker and Docker Compose
- [uv](https://docs.astral.sh/uv/) (Python package manager)
- [pnpm](https://pnpm.io/) (frontend package manager)
- Git

### Setup

```bash
git clone https://github.com/digitranslab/allama.git
cd allama

# Install Python dependencies
uv sync

# Install pre-commit hooks
uv run pre-commit install

# Install frontend dependencies
pnpm install --dir frontend

# Start the development stack
make dev
```

The app is available at [http://localhost](http://localhost) once the stack is running.

### Useful Commands

```bash
make test          # Run all tests
make lint          # Check linting
make lint-fix      # Auto-fix lint issues
make typecheck     # Run type checking
make build-dev     # Rebuild dev containers (after dependency changes)
```

## Workflow

1. Fork the repository
2. Create a branch: `feat/short-description` or `fix/short-description`
3. Make your changes with tests
4. Run `make lint-fix` and `make test`
5. Open a PR against `main`

Keep PRs focused on a single change. Link any related issues.

## Action Templates

Templates live in `packages/allama-registry/allama_registry/templates/`.

Each template is a YAML file that must:
- Follow the template [schema](https://docs.allama.com/integrations/action-templates)
- Use `lower_snake_case` for all `expects` arguments
- Map all required API arguments to `expects`
- Omit optional API arguments unless essential

### Naming Rules

| Field | Rule | Example |
|-------|------|---------|
| `title` | Under 5 words, action only | `Lock device` |
| `description` | Single sentence with integration name | `Lock a device managed by Jamf Pro` |
| `namespace` | `tools.{integration_name}` | `tools.jamf` |

### Template Example

```yaml
type: action
definition:
  title: Lock device
  description: Lock a device managed by Jamf Pro with a 6-digit pin.
  display_group: Jamf
  namespace: tools.jamf
  name: lock_device
  expects:
    device_id:
      type: str
      description: Management ID of the device to lock.
    pin:
      type: str
      description: 6-digit PIN to lock the device.
  steps:
    - ref: lock
      action: core.http_request
      args:
        url: ${{ inputs.base_url }}/api/v2/mdm/commands
        method: POST
        payload:
          clientData:
            managementId: ${{ inputs.device_id }}
          commandData:
            commandType: DEVICE_LOCK
            pin: ${{ inputs.pin }}
  returns: ${{ steps.lock.result }}
```

### Integration Guidelines

- REST APIs: use `core.http_request` or `core.http_poll`
- Return the `.data` field from HTTP results
- Paginated APIs: use `core.http_paginate`
- Ignore `.headers` unless required downstream

## Inline Functions

Functions live in `allama/expressions/functions.py`. Tests are in `tests/unit/test_functions.py`.

```bash
uv run pytest tests/unit/test_functions.py -x --last-failed
```

Always add tests for new functions.

## Testing

```bash
uv run pytest tests/unit        # Backend and inline function tests
uv run pytest tests/registry    # Registry and integration tests
```

Tests run in CI, but please verify locally before opening a PR.

## Reporting Issues

[Open an issue](https://github.com/digitranslab/allama/issues) with:
- Allama version
- Steps to reproduce
- Expected vs actual behaviour

## Code of Conduct

All contributors must follow our [Code of Conduct](CODE_OF_CONDUCT.md).
