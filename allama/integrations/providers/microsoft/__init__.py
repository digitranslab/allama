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
from allama.integrations.providers.microsoft.defender.endpoint import (
    MicrosoftDefenderEndpointACProvider,
    MicrosoftDefenderEndpointCCProvider,
)
from allama.integrations.providers.microsoft.defender.xdr import (
    MicrosoftDefenderXDRACProvider,
    MicrosoftDefenderXDRCCProvider,
)
from allama.integrations.providers.microsoft.graph.entra import (
    MicrosoftEntraACProvider,
    MicrosoftEntraCCProvider,
)
from allama.integrations.providers.microsoft.graph.provider import (
    MicrosoftGraphACProvider,
    MicrosoftGraphCCProvider,
)
from allama.integrations.providers.microsoft.graph.teams import (
    MicrosoftTeamsACProvider,
    MicrosoftTeamsCCProvider,
)

__all__ = [
    "AzureManagementACProvider",
    "AzureManagementCCProvider",
    "MicrosoftSentinelACProvider",
    "MicrosoftSentinelCCProvider",
    "AzureLogAnalyticsACProvider",
    "AzureLogAnalyticsCCProvider",
    "MicrosoftDefenderEndpointACProvider",
    "MicrosoftDefenderEndpointCCProvider",
    "MicrosoftDefenderXDRACProvider",
    "MicrosoftDefenderXDRCCProvider",
    "MicrosoftEntraACProvider",
    "MicrosoftEntraCCProvider",
    "MicrosoftGraphACProvider",
    "MicrosoftGraphCCProvider",
    "MicrosoftTeamsACProvider",
    "MicrosoftTeamsCCProvider",
]
