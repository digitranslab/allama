# API REPL

Interactive Python REPL for authenticated requests to the Allama API.

## Usage

```bash
make dev            # start the dev environment
uv run scripts/api_repl/api_repl.py   # in another terminal
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ALLAMA__PUBLIC_API_URL` | `http://localhost/api` | API base URL |
| `ALLAMA__TEST_USER_EMAIL` | `test@allama.com` | Test user email |
| `ALLAMA__TEST_USER_PASSWORD` | `password1234` | Test user password |
| `ALLAMA__SERVICE_KEY` | — | Service key for internal calls |

## Available in the REPL

Variables: `session`, `base_url`, `user_info`, `service_key`, `console`

Helpers: `pretty_json(data)`, `help_commands()`

## Examples

```python
# List workflows
resp = session.get(f"{base_url}/workflows")
pretty_json(resp.json())

# Create a workflow
resp = session.post(f"{base_url}/workflows", json={
    "title": "My Workflow",
    "description": "Created from REPL"
})

# List secrets
resp = session.get(f"{base_url}/organization/secrets")
pretty_json(resp.json())

# Service-to-service call
from allama.auth.types import system_role
role = system_role()
resp = session.post(
    "http://localhost:8001/api/executor/run/core.transform.reshape",
    headers={"x-allama-service-key": service_key, **role.to_headers()},
    json={...}
)
```

Exit with `Ctrl+D` or `exit()`.
