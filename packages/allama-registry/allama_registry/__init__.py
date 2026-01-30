"""Allama managed actions and integrations registry."""

__version__ = "0.53.13"


from allama_registry import types
from allama_registry._internal import exceptions, registry, secrets
from allama_registry._internal.exceptions import (
    ActionIsInterfaceError,
    RegistryActionError,
    SecretNotFoundError,
)
from allama_registry._internal.logger import logger
from allama_registry._internal.models import (
    RegistryOAuthSecret,
    RegistrySecret,
    RegistrySecretType,
    RegistrySecretTypeValidator,
)

__all__ = [
    "registry",
    "types",
    "RegistrySecret",
    "logger",
    "RegistryOAuthSecret",
    "RegistrySecretType",
    "RegistrySecretTypeValidator",
    "secrets",
    "exceptions",
    "RegistryActionError",
    "ActionIsInterfaceError",
    "SecretNotFoundError",
]
