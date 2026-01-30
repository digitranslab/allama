"""Allama HTTP clients."""

from typing import Any

import httpx

from allama import config
from allama.auth.types import Role
from allama.contexts import ctx_role
from allama.exceptions import AllamaCredentialsError


class AuthenticatedServiceClient(httpx.AsyncClient):
    """An authenticated service client. Typically used by internal services.

    Role precedence
    ---------------
    1. Role passed to the client
    2. Role set in the session role context
    3. Default role Role(type="service", service_id="allama-service")
    """

    def __init__(self, role: Role | None = None, *args: Any, **kwargs: Any):
        super().__init__(*args, **kwargs)
        # Precedence: role > ctx_role > default role. Role is always set.
        resolved_role = role or ctx_role.get()
        if resolved_role is None:
            resolved_role = Role(type="service", service_id="allama-service")
        self.role: Role = resolved_role
        service_key = config.ALLAMA__SERVICE_KEY
        if not service_key:
            raise AllamaCredentialsError(
                "ALLAMA__SERVICE_KEY environment variable not set"
            )
        self.headers["x-allama-service-key"] = service_key
        self.headers.update(self.role.to_headers())


class AuthenticatedAPIClient(AuthenticatedServiceClient):
    """An authenticated httpx client to hit main API endpoints.

     Role precedence
    ---------------
    1. Role passed to the client
    2. Role set in the session role context
    3. Default role Role(type="service", service_id="allama-service")
    """

    def __init__(self, role: Role | None = None, *args: Any, **kwargs: Any):
        kwargs["role"] = role
        kwargs["base_url"] = config.ALLAMA__API_URL
        super().__init__(*args, **kwargs)
