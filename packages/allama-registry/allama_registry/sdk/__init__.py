"""Allama SDK for registry actions.

This SDK provides HTTP clients for accessing Allama platform features
from within UDF actions running in sandboxed environments.
"""

from allama_registry.sdk.cases import CasesClient
from allama_registry.sdk.client import AllamaClient
from allama_registry.sdk.tables import TablesClient

from allama_registry.sdk.exceptions import (
    AllamaAPIError,
    AllamaAuthError,
    AllamaConflictError,
    AllamaNotFoundError,
    AllamaSDKError,
    AllamaValidationError,
)
from allama_registry.sdk.types import (
    UNSET,
    CasePriority,
    CaseSeverity,
    CaseStatus,
    SqlType,
    Unset,
    is_set,
)

__all__ = [
    # Main client
    "AllamaClient",
    # Sub-clients
    "CasesClient",
    "TablesClient",
    # Exceptions
    "AllamaAPIError",
    "AllamaAuthError",
    "AllamaConflictError",
    "AllamaNotFoundError",
    "AllamaSDKError",
    "AllamaValidationError",
    # Sentinel types and helpers
    "UNSET",
    "Unset",
    "is_set",
    # Case types
    "CasePriority",
    "CaseSeverity",
    "CaseStatus",
    # Table types
    "SqlType",
]
