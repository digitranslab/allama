from typing import Final

from allama.integrations.providers.base import BaseOAuthProvider
from allama.integrations.providers.github.mcp import GitHubMCPProvider
from allama.integrations.providers.github.oauth import GitHubOAuthProvider
from allama.integrations.providers.google import (
    GoogleDocsOAuthProvider,
    GoogleServiceAccountOAuthProvider,
    GoogleSheetsOAuthProvider,
)
from allama.integrations.providers.google.drive import GoogleDriveACProvider
from allama.integrations.providers.google.gmail import GoogleGmailACProvider
from allama.integrations.providers.linear.mcp import LinearMCPProvider
from allama.integrations.providers.microsoft import (
    AzureLogAnalyticsACProvider,
    AzureLogAnalyticsCCProvider,
    AzureManagementACProvider,
    AzureManagementCCProvider,
    MicrosoftDefenderEndpointACProvider,
    MicrosoftDefenderEndpointCCProvider,
    MicrosoftDefenderXDRACProvider,
    MicrosoftDefenderXDRCCProvider,
    MicrosoftEntraACProvider,
    MicrosoftEntraCCProvider,
    MicrosoftGraphACProvider,
    MicrosoftGraphCCProvider,
    MicrosoftSentinelACProvider,
    MicrosoftSentinelCCProvider,
    MicrosoftTeamsACProvider,
    MicrosoftTeamsCCProvider,
)
from allama.integrations.providers.notion.mcp import NotionMCPProvider
from allama.integrations.providers.runreveal.mcp import RunRevealMCPProvider
from allama.integrations.providers.secureannex.mcp import SecureAnnexMCPProvider
from allama.integrations.providers.sentry.mcp import SentryMCPProvider
from allama.integrations.providers.servicenow.oauth import ServiceNowOAuthProvider
from allama.integrations.providers.slack.oauth import SlackOAuthProvider
from allama.integrations.schemas import ProviderKey

_PROVIDER_CLASSES: list[type[BaseOAuthProvider]] = [
    GitHubOAuthProvider,
    GitHubMCPProvider,
    GoogleDocsOAuthProvider,
    GoogleDriveACProvider,
    GoogleGmailACProvider,
    GoogleServiceAccountOAuthProvider,
    GoogleSheetsOAuthProvider,
    LinearMCPProvider,
    NotionMCPProvider,
    RunRevealMCPProvider,
    SecureAnnexMCPProvider,
    SentryMCPProvider,
    AzureManagementACProvider,
    AzureManagementCCProvider,
    MicrosoftSentinelACProvider,
    MicrosoftSentinelCCProvider,
    AzureLogAnalyticsACProvider,
    AzureLogAnalyticsCCProvider,
    MicrosoftDefenderEndpointACProvider,
    MicrosoftDefenderEndpointCCProvider,
    MicrosoftDefenderXDRACProvider,
    MicrosoftDefenderXDRCCProvider,
    MicrosoftEntraACProvider,
    MicrosoftEntraCCProvider,
    MicrosoftGraphACProvider,
    MicrosoftGraphCCProvider,
    MicrosoftTeamsACProvider,
    MicrosoftTeamsCCProvider,
    SlackOAuthProvider,
    ServiceNowOAuthProvider,
]


def _build_provider_registry() -> dict[ProviderKey, type[BaseOAuthProvider]]:
    """Build provider registry with duplicate detection."""
    registry: dict[ProviderKey, type[BaseOAuthProvider]] = {}
    for cls in _PROVIDER_CLASSES:
        if not getattr(cls, "_include_in_registry", True):
            continue
        key = ProviderKey(id=cls.id, grant_type=cls.grant_type)
        if key in registry:
            raise ValueError(
                f"Duplicate provider key {key} for {cls.__name__} "
                f"(already registered by {registry[key].__name__})"
            )
        registry[key] = cls
    return registry


PROVIDER_REGISTRY: Final[dict[ProviderKey, type[BaseOAuthProvider]]] = (
    _build_provider_registry()
)


def get_provider_class(key: ProviderKey) -> type[BaseOAuthProvider] | None:
    """Return the provider class matching *key*, or ``None``."""
    return PROVIDER_REGISTRY.get(key)


def all_providers() -> list[type[BaseOAuthProvider]]:
    """Return all registered provider classes."""
    return list(PROVIDER_REGISTRY.values())
