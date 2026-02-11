"""Microsoft Graph OAuth providers."""

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
    "MicrosoftEntraACProvider",
    "MicrosoftEntraCCProvider",
    "MicrosoftGraphACProvider",
    "MicrosoftGraphCCProvider",
    "MicrosoftTeamsACProvider",
    "MicrosoftTeamsCCProvider",
]
