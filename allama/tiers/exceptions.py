"""Tier-specific exceptions."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from allama.exceptions import AllamaException, AllamaNotFoundError

if TYPE_CHECKING:
    from allama.identifiers import OrganizationID


class TierError(AllamaException):
    """Base exception for tier-related errors."""


class TierNotFoundError(AllamaNotFoundError):
    """Raised when a tier is not found."""


class OrganizationNotFoundError(AllamaNotFoundError):
    """Raised when an organization is not found."""

    def __init__(self, org_id: OrganizationID):
        super().__init__(f"Organization {org_id} not found")
        self.org_id = org_id


class DefaultTierNotConfiguredError(TierError):
    """Raised when no default tier is configured."""

    def __init__(self):
        super().__init__("No default tier configured. Run database migrations.")


class CannotDeleteDefaultTierError(TierError):
    """Raised when attempting to delete the default tier."""

    def __init__(self):
        super().__init__("Cannot delete the default tier")


class TierInUseError(TierError):
    """Raised when attempting to delete a tier that has organizations assigned."""

    def __init__(self, tier_id: uuid.UUID):
        super().__init__(
            f"Cannot delete tier '{tier_id}': organizations are still assigned to it"
        )
        self.tier_id = tier_id
