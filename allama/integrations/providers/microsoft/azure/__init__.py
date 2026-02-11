"""Azure OAuth providers."""

from allama.integrations.providers.microsoft.azure.loganalytics import (
    AzureLogAnalyticsACProvider,
    AzureLogAnalyticsCCProvider,
)
from allama.integrations.providers.microsoft.azure.provider import (
    AzureManagementACProvider,
    AzureManagementCCProvider,
)
from allama.integrations.providers.microsoft.azure.sentinel import (
    MicrosoftSentinelACProvider,
    MicrosoftSentinelCCProvider,
)

__all__ = [
    "AzureManagementACProvider",
    "AzureManagementCCProvider",
    "MicrosoftSentinelACProvider",
    "MicrosoftSentinelCCProvider",
    "AzureLogAnalyticsACProvider",
    "AzureLogAnalyticsCCProvider",
]
