import os
import uuid

import pytest
from httpx import AsyncClient

from allama import config
from allama.auth.types import Role
from allama.clients import AuthenticatedAPIClient, AuthenticatedServiceClient
from allama.contexts import ctx_role

pytest.mark.disable_fixture("test_user")


@pytest.mark.anyio
async def test_authenticated_service_client(mock_user_id, mock_org_id):
    service_role = Role(
        type="service", user_id=mock_user_id, service_id="allama-runner"
    )
    async with AuthenticatedServiceClient(role=service_role) as client:
        assert isinstance(client, AsyncClient)
        assert client.role == service_role
        assert client.headers["x-allama-role-service-id"] == "allama-runner"
        assert (
            client.headers["x-allama-service-key"]
            == os.environ["ALLAMA__SERVICE_KEY"]
        )
        assert uuid.UUID(client.headers["x-allama-role-user-id"]) == mock_user_id
        assert "x-allama-role-workspace-id" not in client.headers

    service_role = Role(type="service", service_id="allama-runner")
    async with AuthenticatedServiceClient(role=service_role) as client:
        assert isinstance(client, AsyncClient)
        assert client.role == service_role
        assert client.headers["x-allama-role-service-id"] == "allama-runner"
        assert (
            client.headers["x-allama-service-key"]
            == os.environ["ALLAMA__SERVICE_KEY"]
        )
        assert "x-allama-role-user-id" not in client.headers
        assert "x-allama-role-workspace-id" not in client.headers

    service_role = Role(
        type="service",
        service_id="allama-runner",
        workspace_id=mock_org_id,
        user_id=mock_user_id,
    )
    async with AuthenticatedServiceClient(role=service_role) as client:
        assert isinstance(client, AsyncClient)
        assert client.role == service_role
        assert client.headers["x-allama-role-service-id"] == "allama-runner"
        assert (
            client.headers["x-allama-service-key"]
            == os.environ["ALLAMA__SERVICE_KEY"]
        )
        assert uuid.UUID(client.headers["x-allama-role-user-id"]) == mock_user_id
        assert uuid.UUID(client.headers["x-allama-role-workspace-id"]) == mock_org_id


@pytest.mark.anyio
async def test_authenticated_service_client_init_with_role(mock_user_id):
    # Test initialization of AuthenticatedServiceClient
    role = Role(type="service", user_id=mock_user_id, service_id="allama-runner")
    async with AuthenticatedServiceClient(role=role) as client:
        assert isinstance(client, AsyncClient)
        assert client.role == role
        assert client.headers["x-allama-role-service-id"] == "allama-runner"
        assert (
            client.headers["x-allama-service-key"]
            == os.environ["ALLAMA__SERVICE_KEY"]
        )
        assert uuid.UUID(client.headers["x-allama-role-user-id"]) == mock_user_id
        assert "x-allama-role-workspace-id" not in client.headers


@pytest.mark.anyio
async def test_authenticated_service_client_init_no_role():
    """Test initialization of AuthenticatedServiceClient without role

    Expect:
    - role is the default role
    - headers are set with the default role
    - no user id in the headers
    """

    default_role = Role(type="service", service_id="allama-service")
    async with AuthenticatedServiceClient() as client:
        assert isinstance(client, AsyncClient)
        assert client.role == default_role
        assert client.headers["x-allama-role-service-id"] == "allama-service"
        assert (
            client.headers["x-allama-service-key"]
            == os.environ["ALLAMA__SERVICE_KEY"]
        )
        assert "x-allama-role-user-id" not in client.headers


@pytest.mark.anyio
async def test_authenticated_service_client_init_role_from_context(mock_user_id):
    # Test initialization of AuthenticatedServiceClient without role
    mock_ctx_role = Role(
        type="service",
        user_id=mock_user_id,
        service_id="allama-service",
    )
    ctx_role.set(mock_ctx_role)

    async with AuthenticatedServiceClient() as client:
        assert client.role == mock_ctx_role
        assert client.headers["x-allama-role-service-id"] == "allama-service"
        assert (
            client.headers["x-allama-service-key"]
            == os.environ["ALLAMA__SERVICE_KEY"]
        )
        assert uuid.UUID(client.headers["x-allama-role-user-id"]) == mock_user_id


@pytest.mark.anyio
async def test_authenticated_api_client_init_role_from_context(mock_user_id):
    # Test initialization of AuthenticatedAPIClient without role
    mock_ctx_role = Role(
        type="service",
        user_id=mock_user_id,
        service_id="allama-service",
    )
    ctx_role.set(mock_ctx_role)

    async with AuthenticatedAPIClient() as client:
        assert client.role == mock_ctx_role
        assert client.headers["x-allama-role-service-id"] == "allama-service"
        assert (
            client.headers["x-allama-service-key"]
            == os.environ["ALLAMA__SERVICE_KEY"]
        )
        assert uuid.UUID(client.headers["x-allama-role-user-id"]) == mock_user_id
        assert client.base_url == config.ALLAMA__API_URL


@pytest.mark.anyio
async def test_authenticated_api_client_init_no_role():
    # Test initialization of AuthenticatedAPIClient without role
    default_role = Role(type="service", service_id="allama-service")
    async with AuthenticatedAPIClient() as client:
        assert client.role == default_role
        assert client.headers["x-allama-role-service-id"] == "allama-service"
        assert (
            client.headers["x-allama-service-key"]
            == os.environ["ALLAMA__SERVICE_KEY"]
        )
        assert "x-allama-role-user-id" not in client.headers
        assert client.base_url == config.ALLAMA__API_URL


@pytest.mark.anyio
async def test_authenticated_api_client_init_with_role(mock_user_id, mock_org_id):
    # Test initialization of AuthenticatedAPIClient
    role = Role(
        type="service",
        user_id=mock_user_id,
        service_id="allama-runner",
        workspace_id=mock_org_id,
    )
    async with AuthenticatedAPIClient(role=role) as client:
        assert isinstance(client, AsyncClient)
        assert client.role == role
        assert client.headers["x-allama-role-service-id"] == "allama-runner"
        assert (
            client.headers["x-allama-service-key"]
            == os.environ["ALLAMA__SERVICE_KEY"]
        )
        assert uuid.UUID(client.headers["x-allama-role-user-id"]) == mock_user_id
        assert uuid.UUID(client.headers["x-allama-role-workspace-id"]) == mock_org_id
        assert client.base_url == config.ALLAMA__API_URL

    role = Role(type="service", service_id="allama-runner", workspace_id=mock_org_id)
    async with AuthenticatedAPIClient(role=role) as client:
        assert client.role == role
        assert client.headers["x-allama-role-service-id"] == "allama-runner"
        assert (
            client.headers["x-allama-service-key"]
            == os.environ["ALLAMA__SERVICE_KEY"]
        )
        assert "x-allama-role-user-id" not in client.headers
        assert uuid.UUID(client.headers["x-allama-role-workspace-id"]) == mock_org_id
        assert client.base_url == config.ALLAMA__API_URL
