# Allama Admin CLI

CLI tool for Allama platform operators to manage infrastructure and control plane operations.

## Installation

```bash
# Install the CLI
pip install allama-admin

# For bootstrap operations (create-superuser with direct DB access)
pip install allama-admin[bootstrap]
```

## Configuration

The CLI uses environment variables for configuration:

| Variable | Description | Required |
|----------|-------------|----------|
| `ALLAMA__API_URL` | Allama API URL (default: `http://localhost:8000`) | No |
| `ALLAMA__SERVICE_KEY` | Service key for API authentication | Yes (for API commands) |
| `ALLAMA__DB_URI` | Database URI for direct DB operations | Yes (for bootstrap/migrate) |

## Commands

### Admin Commands

```bash
# List all users
allama admin list-users

# Get user details
allama admin get-user <user-id>

# Promote a user to superuser (via API)
allama admin promote-user --email user@example.com

# Demote a user from superuser (via API)
allama admin demote-user --email user@example.com

# Create a superuser (direct DB - for bootstrap)
allama admin create-superuser --email admin@example.com

# Create a new user and promote to superuser
allama admin create-superuser --email admin@example.com --create
```

### Organization Commands

```bash
# List all organizations
allama orgs list

# Create a new organization
allama orgs create --name "My Org" --slug "my-org"

# Get organization details
allama orgs get <org-id>
```

### Registry Commands

```bash
# Sync all registry repositories
allama registry sync

# Sync a specific repository
allama registry sync --repository-id <repo-id>

# Get registry status
allama registry status

# List registry versions
allama registry versions
```

### Migration Commands

```bash
# Upgrade database to latest
allama migrate upgrade head

# Upgrade to specific revision
allama migrate upgrade <revision>

# Downgrade database
allama migrate downgrade -1

# Show current migration status
allama migrate status

# Show migration history
allama migrate history
```

## Output Formats

All commands support JSON output with the `--json` or `-j` flag:

```bash
allama admin list-users --json
allama orgs list -j
```

## Development

```bash
# Install in development mode
pip install -e packages/allama-admin

# Run the CLI
allama --help
```
