"""Tests for the Variables SDK client.

These tests use mocking and don't require database or other infrastructure.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import pytest
from allama_registry.sdk.exceptions import AllamaNotFoundError
from allama_registry.sdk.variables import VariablesClient


@pytest.fixture
def mock_allama_client() -> MagicMock:
    """Create a mock AllamaClient."""
    client = MagicMock()
    client.get = AsyncMock()
    return client


@pytest.fixture
def variables_client(mock_allama_client: MagicMock) -> VariablesClient:
    """Create a VariablesClient with mocked HTTP client."""
    return VariablesClient(mock_allama_client)


class TestVariablesClientGet:
    """Tests for VariablesClient.get()."""

    @pytest.mark.anyio
    async def test_get_returns_value(
        self, variables_client: VariablesClient, mock_allama_client: MagicMock
    ):
        """Test get returns the value for the specified key."""
        mock_allama_client.get.return_value = "https://api.example.com"

        result = await variables_client.get("api_config", "base_url")

        assert result == "https://api.example.com"
        mock_allama_client.get.assert_called_once_with(
            "/variables/api_config/value", params={"key": "base_url"}
        )

    @pytest.mark.anyio
    async def test_get_with_environment(
        self, variables_client: VariablesClient, mock_allama_client: MagicMock
    ):
        """Test get passes environment parameter."""
        mock_allama_client.get.return_value = "prod-value"

        result = await variables_client.get(
            "api_config", "base_url", environment="production"
        )

        assert result == "prod-value"
        mock_allama_client.get.assert_called_once_with(
            "/variables/api_config/value",
            params={"key": "base_url", "environment": "production"},
        )

    @pytest.mark.anyio
    async def test_get_returns_none_for_missing_key(
        self, variables_client: VariablesClient, mock_allama_client: MagicMock
    ):
        """Test get returns None when the key doesn't exist."""
        mock_allama_client.get.return_value = None

        result = await variables_client.get("api_config", "nonexistent_key")

        assert result is None

    @pytest.mark.anyio
    async def test_get_raises_not_found_for_missing_variable(
        self, variables_client: VariablesClient, mock_allama_client: MagicMock
    ):
        """Test get raises AllamaNotFoundError when variable doesn't exist."""
        mock_allama_client.get.side_effect = AllamaNotFoundError(
            resource="Variable", identifier="nonexistent"
        )

        with pytest.raises(AllamaNotFoundError):
            await variables_client.get("nonexistent", "key")


class TestVariablesClientGetOrDefault:
    """Tests for VariablesClient.get_or_default()."""

    @pytest.mark.anyio
    async def test_get_or_default_returns_value_when_exists(
        self, variables_client: VariablesClient, mock_allama_client: MagicMock
    ):
        """Test get_or_default returns the value when it exists."""
        mock_allama_client.get.return_value = 60

        result = await variables_client.get_or_default("api_config", "timeout", 30)

        assert result == 60

    @pytest.mark.anyio
    async def test_get_or_default_returns_default_when_not_found(
        self, variables_client: VariablesClient, mock_allama_client: MagicMock
    ):
        """Test get_or_default returns default when variable doesn't exist."""
        mock_allama_client.get.side_effect = AllamaNotFoundError(
            resource="Variable", identifier="nonexistent"
        )

        result = await variables_client.get_or_default("nonexistent", "key", "default")

        assert result == "default"

    @pytest.mark.anyio
    async def test_get_or_default_returns_default_when_value_is_none(
        self, variables_client: VariablesClient, mock_allama_client: MagicMock
    ):
        """Test get_or_default returns default when value is None."""
        mock_allama_client.get.return_value = None

        result = await variables_client.get_or_default("api_config", "missing_key", 42)

        assert result == 42

    @pytest.mark.anyio
    async def test_get_or_default_with_environment(
        self, variables_client: VariablesClient, mock_allama_client: MagicMock
    ):
        """Test get_or_default passes environment parameter."""
        mock_allama_client.get.return_value = "env-value"

        result = await variables_client.get_or_default(
            "api_config", "key", "default", environment="staging"
        )

        assert result == "env-value"
        mock_allama_client.get.assert_called_once_with(
            "/variables/api_config/value",
            params={"key": "key", "environment": "staging"},
        )


class TestVariablesClientGetVariable:
    """Tests for VariablesClient.get_variable()."""

    @pytest.mark.anyio
    async def test_get_variable_returns_metadata(
        self, variables_client: VariablesClient, mock_allama_client: MagicMock
    ):
        """Test get_variable returns full variable metadata."""
        mock_allama_client.get.return_value = {
            "id": "var-123",
            "name": "api_config",
            "description": "API configuration",
            "values": {"base_url": "https://api.example.com", "timeout": 30},
            "environment": "default",
        }

        result = await variables_client.get_variable("api_config")

        assert result["name"] == "api_config"
        assert result["values"]["base_url"] == "https://api.example.com"
        assert result["values"]["timeout"] == 30
        mock_allama_client.get.assert_called_once_with(
            "/variables/api_config", params=None
        )

    @pytest.mark.anyio
    async def test_get_variable_with_environment(
        self, variables_client: VariablesClient, mock_allama_client: MagicMock
    ):
        """Test get_variable passes environment parameter."""
        mock_allama_client.get.return_value = {
            "id": "var-456",
            "name": "api_config",
            "description": "Production API configuration",
            "values": {"base_url": "https://prod.example.com"},
            "environment": "production",
        }

        result = await variables_client.get_variable(
            "api_config", environment="production"
        )

        assert result["environment"] == "production"
        mock_allama_client.get.assert_called_once_with(
            "/variables/api_config", params={"environment": "production"}
        )

    @pytest.mark.anyio
    async def test_get_variable_raises_not_found(
        self, variables_client: VariablesClient, mock_allama_client: MagicMock
    ):
        """Test get_variable raises AllamaNotFoundError when variable doesn't exist."""
        mock_allama_client.get.side_effect = AllamaNotFoundError(
            resource="Variable", identifier="nonexistent"
        )

        with pytest.raises(AllamaNotFoundError):
            await variables_client.get_variable("nonexistent")
