"""Base HTTP client for Allama API."""

from __future__ import annotations

import os
from typing import TYPE_CHECKING, Any

import httpx

from allama_registry.sdk.exceptions import (
    AllamaAPIError,
    AllamaAuthError,
    AllamaConflictError,
    AllamaNotFoundError,
    AllamaValidationError,
)

if TYPE_CHECKING:
    from allama_registry.sdk.agents import AgentsClient
    from allama_registry.sdk.cases import CasesClient
    from allama_registry.sdk.tables import TablesClient
    from allama_registry.sdk.variables import VariablesClient
    from allama_registry.sdk.workflows import WorkflowsClient


class AllamaClient:
    """HTTP client for Allama API with JWT authentication.

    This client is used by registry actions to communicate with the
    Allama API when running in a sandboxed environment.

    Configuration is read from environment variables:
    - ALLAMA__API_URL: Base URL of the Allama API
    - ALLAMA__EXECUTOR_TOKEN: JWT token for authentication
    - ALLAMA__WORKSPACE_ID: Current workspace ID (added to requests)
    """

    def __init__(
        self,
        *,
        api_url: str | None = None,
        token: str | None = None,
        workspace_id: str | None = None,
        timeout: float = 120.0,
    ) -> None:
        """Initialize the client.

        Args:
            api_url: Base URL of the Allama API. Defaults to ALLAMA__API_URL env var.
            token: JWT token for authentication. Defaults to ALLAMA__EXECUTOR_TOKEN env var.
            workspace_id: Workspace ID. Defaults to ALLAMA__WORKSPACE_ID env var.
            timeout: Request timeout in seconds.
        """
        base_url = api_url or os.environ.get("ALLAMA__API_URL", "http://api:8000")
        # Ensure /internal suffix is present
        if not base_url.endswith("/internal"):
            base_url = base_url.rstrip("/") + "/internal"
        self._api_url = base_url

        self._token = token or os.environ.get("ALLAMA__EXECUTOR_TOKEN", "")
        self._workspace_id = workspace_id or os.environ.get(
            "ALLAMA__WORKSPACE_ID", ""
        )
        self._timeout = timeout

        # Lazily initialized sub-clients
        self._agents: AgentsClient | None = None
        self._cases: CasesClient | None = None
        self._tables: TablesClient | None = None
        self._variables: VariablesClient | None = None
        self._workflows: WorkflowsClient | None = None

    @property
    def api_url(self) -> str:
        """Base URL of the Allama API."""
        return self._api_url

    @property
    def workspace_id(self) -> str:
        """Current workspace ID."""
        return self._workspace_id

    @property
    def cases(self) -> CasesClient:
        """Cases API client."""
        if self._cases is None:
            from allama_registry.sdk.cases import CasesClient

            self._cases = CasesClient(self)
        return self._cases

    @property
    def agents(self) -> AgentsClient:
        """Agents API client."""
        if self._agents is None:
            from allama_registry.sdk.agents import AgentsClient

            self._agents = AgentsClient(self)
        return self._agents

    @property
    def tables(self) -> TablesClient:
        """Tables API client."""
        if self._tables is None:
            from allama_registry.sdk.tables import TablesClient

            self._tables = TablesClient(self)
        return self._tables

    @property
    def variables(self) -> VariablesClient:
        """Variables API client."""
        if self._variables is None:
            from allama_registry.sdk.variables import VariablesClient

            self._variables = VariablesClient(self)
        return self._variables

    @property
    def workflows(self) -> WorkflowsClient:
        """Workflows API client."""
        if self._workflows is None:
            from allama_registry.sdk.workflows import WorkflowsClient

            self._workflows = WorkflowsClient(self)
        return self._workflows

    def _get_headers(self) -> dict[str, str]:
        """Get default headers for requests."""
        headers = {
            "Content-Type": "application/json",
        }
        if self._token:
            headers["Authorization"] = f"Bearer {self._token}"
        return headers

    def _handle_error_response(self, response: httpx.Response) -> None:
        """Convert HTTP error responses to SDK exceptions."""
        status_code = response.status_code

        # Try to extract detail from JSON response
        detail: str | None = None
        try:
            data = response.json()
            if isinstance(data, dict):
                detail = data.get("detail")
        except Exception:
            detail = response.text or None

        if status_code == 401:
            raise AllamaAuthError(detail=detail, status_code=401)
        elif status_code == 403:
            raise AllamaAuthError(detail=detail, status_code=403)
        elif status_code == 404:
            raise AllamaNotFoundError(resource="Resource", identifier=detail)
        elif status_code == 409:
            raise AllamaConflictError(detail=detail)
        elif status_code in (400, 422):
            raise AllamaValidationError(detail=detail, status_code=status_code)
        else:
            raise AllamaAPIError(
                message="API request failed",
                status_code=status_code,
                detail=detail,
            )

    async def request(
        self,
        method: str,
        path: str,
        *,
        params: dict[str, Any] | None = None,
        json: Any | None = None,
        headers: dict[str, str] | None = None,
    ) -> Any:
        """Make an authenticated HTTP request to the API.

        Args:
            method: HTTP method (GET, POST, PUT, DELETE, etc.)
            path: API path (e.g., "/cases")
            params: Query parameters
            json: JSON body data
            headers: Additional headers

        Returns:
            Parsed JSON response, or None if response has no content.

        Raises:
            AllamaAuthError: For 401/403 responses
            AllamaNotFoundError: For 404 responses
            AllamaValidationError: For 400/422 responses
            AllamaAPIError: For other error responses
        """
        url = f"{self._api_url}{path}"
        request_headers = self._get_headers()
        if headers:
            request_headers.update(headers)

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            response = await client.request(
                method,
                url,
                params=params,
                json=json,
                headers=request_headers,
            )

        if not response.is_success:
            self._handle_error_response(response)

        # Return None for empty responses (204 No Content, etc.)
        if not response.content:
            return None

        return response.json()

    async def get(
        self,
        path: str,
        *,
        params: dict[str, Any] | None = None,
    ) -> Any:
        """Make a GET request."""
        return await self.request("GET", path, params=params)

    async def post(
        self,
        path: str,
        *,
        params: dict[str, Any] | None = None,
        json: Any | None = None,
    ) -> Any:
        """Make a POST request."""
        return await self.request("POST", path, params=params, json=json)

    async def put(
        self,
        path: str,
        *,
        params: dict[str, Any] | None = None,
        json: Any | None = None,
    ) -> Any:
        """Make a PUT request."""
        return await self.request("PUT", path, params=params, json=json)

    async def patch(
        self,
        path: str,
        *,
        params: dict[str, Any] | None = None,
        json: Any | None = None,
    ) -> Any:
        """Make a PATCH request."""
        return await self.request("PATCH", path, params=params, json=json)

    async def delete(
        self,
        path: str,
        *,
        params: dict[str, Any] | None = None,
    ) -> Any:
        """Make a DELETE request."""
        return await self.request("DELETE", path, params=params)
