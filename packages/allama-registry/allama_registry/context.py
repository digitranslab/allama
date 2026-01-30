"""Registry execution context.

This module provides context management for registry actions running
in sandboxed environments. The context is injected from environment
variables and provides access to platform services via the SDK.
"""

from __future__ import annotations

import os
from contextvars import ContextVar
from dataclasses import dataclass, field
from functools import cached_property
from typing import TYPE_CHECKING


if TYPE_CHECKING:
    from allama_registry.sdk.agents import AgentsClient
    from allama_registry.sdk.cases import CasesClient
    from allama_registry.sdk.client import AllamaClient
    from allama_registry.sdk.tables import TablesClient
    from allama_registry.sdk.variables import VariablesClient
    from allama_registry.sdk.workflows import WorkflowsClient


@dataclass
class RegistryContext:
    """Execution context for registry actions.

    This context is populated from environment variables when a UDF
    executes in a sandbox. It provides access to platform services
    via the SDK client.

    Attributes:
        workspace_id: The workspace UUID where the workflow is running.
        workflow_id: The workflow UUID being executed.
        run_id: The workflow run UUID.
        wf_exec_id: The full workflow execution ID (for correlation).
        environment: The execution environment (e.g., "default").
        api_url: The Allama API URL.
        executor_url: The Allama executor service URL (sandbox execution).
        token: The executor JWT for authentication.
    """

    workspace_id: str
    workflow_id: str
    run_id: str
    wf_exec_id: str | None = None
    environment: str = "default"
    api_url: str = "http://api:8000"
    executor_url: str = "http://executor:8000"
    token: str = ""

    # Lazily initialized SDK client
    _client: AllamaClient | None = field(default=None, repr=False)

    @classmethod
    def from_env(cls) -> RegistryContext:
        """Create a context from environment variables.

        Expected environment variables:
        - ALLAMA__WORKSPACE_ID: Workspace UUID
        - ALLAMA__WORKFLOW_ID: Workflow UUID
        - ALLAMA__RUN_ID: Run UUID
        - ALLAMA__WF_EXEC_ID: Full workflow execution ID (for correlation)
        - ALLAMA__ENVIRONMENT: Execution environment (default: "default")
        - ALLAMA__API_URL: API URL (default: "http://api:8000")
        - ALLAMA__EXECUTOR_URL: Executor URL (default: "http://executor:8000")
        - ALLAMA__EXECUTOR_TOKEN: JWT token for authentication

        Returns:
            RegistryContext populated from environment.

        Raises:
            ValueError: If required environment variables are missing.
        """
        workspace_id = os.environ.get("ALLAMA__WORKSPACE_ID")
        workflow_id = os.environ.get("ALLAMA__WORKFLOW_ID")
        run_id = os.environ.get("ALLAMA__RUN_ID")

        if not workspace_id:
            raise ValueError("ALLAMA__WORKSPACE_ID environment variable is required")
        if not workflow_id:
            raise ValueError("ALLAMA__WORKFLOW_ID environment variable is required")
        if not run_id:
            raise ValueError("ALLAMA__RUN_ID environment variable is required")

        return cls(
            workspace_id=workspace_id,
            workflow_id=workflow_id,
            run_id=run_id,
            wf_exec_id=os.environ.get("ALLAMA__WF_EXEC_ID"),
            environment=os.environ.get("ALLAMA__ENVIRONMENT", "default"),
            api_url=os.environ.get("ALLAMA__API_URL", "http://api:8000"),
            executor_url=os.environ.get(
                "ALLAMA__EXECUTOR_URL", "http://executor:8000"
            ),
            token=os.environ.get("ALLAMA__EXECUTOR_TOKEN", ""),
        )

    @cached_property
    def client(self) -> AllamaClient:
        """Get the SDK client for this context."""
        from allama_registry.sdk.client import AllamaClient

        return AllamaClient(
            api_url=self.api_url,
            token=self.token,
            workspace_id=self.workspace_id,
        )

    @property
    def cases(self) -> "CasesClient":
        """Get the Cases API client."""
        return self.client.cases

    @property
    def agents(self) -> "AgentsClient":
        """Get the Agents API client."""
        return self.client.agents

    @property
    def tables(self) -> "TablesClient":
        """Get the Tables API client."""
        return self.client.tables

    @property
    def variables(self) -> "VariablesClient":
        """Get the Variables API client."""
        return self.client.variables

    @property
    def workflows(self) -> "WorkflowsClient":
        """Get the Workflows API client."""
        return self.client.workflows


# Context variable for the current registry context
_ctx: ContextVar[RegistryContext | None] = ContextVar("registry_context", default=None)


def get_context() -> RegistryContext:
    """Get the current registry context.

    Returns:
        The current RegistryContext.

    Raises:
        RuntimeError: If no context is set.
    """
    ctx = _ctx.get()
    if ctx is None:
        raise RuntimeError(
            "No registry context is set. "
            "Context must be set before calling registry actions."
        )
    return ctx


def set_context(ctx: RegistryContext) -> None:
    """Set the current registry context.

    Args:
        ctx: The context to set.
    """
    _ctx.set(ctx)


def clear_context() -> None:
    """Clear the current registry context."""
    _ctx.set(None)


def init_context_from_env() -> RegistryContext:
    """Initialize and set context from environment variables.

    This is a convenience function that creates a context from
    environment variables and sets it as the current context.

    Returns:
        The initialized RegistryContext.
    """
    ctx = RegistryContext.from_env()
    set_context(ctx)
    return ctx
