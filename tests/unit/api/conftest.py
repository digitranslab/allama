"""Minimal fixtures for HTTP-level API route testing."""

from collections.abc import Generator
from typing import get_args
from unittest.mock import AsyncMock

import pytest
from fastapi.testclient import TestClient

from allama.agent.router import (
    OrganizationAdminUserRole,
    OrganizationUserRole,
)
from allama.api.app import app
from allama.auth.credentials import SuperuserRole
from allama.auth.dependencies import ExecutorWorkspaceRole, WorkspaceUserRole
from allama.auth.types import Role
from allama.cases.router import WorkspaceUser
from allama.contexts import ctx_role
from allama.db.engine import get_async_session
from allama.secrets.router import (
    OrgAdminUser,
    WorkspaceAdminUser,
)
from allama.secrets.router import (
    WorkspaceUser as SecretsWorkspaceUser,
)
from allama.tables.router import (
    WorkspaceEditorUser as TablesWorkspaceEditorUser,
)
from allama.tables.router import (
    WorkspaceUser as TablesWorkspaceUser,
)
from allama.workspaces.router import (
    OrgAdminUser as WorkspacesOrgAdminUser,
)
from allama.workspaces.router import (
    OrgUser,
    WorkspaceAdminUserInPath,
    WorkspaceUserInPath,
)


def override_role_dependency() -> Role:
    """Override role dependencies to use ctx_role from test fixtures."""
    role = ctx_role.get()
    if role is None:
        raise RuntimeError("No role set in ctx_role context")
    return role


@pytest.fixture
def client() -> Generator[TestClient, None, None]:
    """Create FastAPI test client.

    Uses the existing app instance and relies on ctx_role context
    from test_role/test_admin_role fixtures for authentication.
    """

    # List of Annotated role dependencies to override
    role_dependencies = [
        WorkspaceUserRole,
        ExecutorWorkspaceRole,
        WorkspaceUser,
        WorkspaceUserInPath,
        WorkspaceAdminUserInPath,
        SuperuserRole,
        OrganizationUserRole,
        OrganizationAdminUserRole,
        OrgUser,
        WorkspacesOrgAdminUser,
        SecretsWorkspaceUser,
        WorkspaceAdminUser,
        OrgAdminUser,
        TablesWorkspaceUser,
        TablesWorkspaceEditorUser,
    ]

    for annotated_type in role_dependencies:
        # Extract the Depends object from the Annotated type
        metadata = get_args(annotated_type)
        if metadata and hasattr(metadata[1], "dependency"):
            original_dependency = metadata[1].dependency
            # Override the actual dependency function
            app.dependency_overrides[original_dependency] = override_role_dependency

    mock_session = AsyncMock(name="mock_async_session")

    async def override_get_async_session() -> AsyncMock:
        """Return a mock DB session so HTTP tests do not hit Postgres."""
        return mock_session

    app.dependency_overrides[get_async_session] = override_get_async_session

    client = TestClient(app, raise_server_exceptions=False)
    yield client
    # Clean up overrides
    app.dependency_overrides.clear()
