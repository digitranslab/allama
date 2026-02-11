"""Allama exceptions

Note
----
This module contains exceptions that are user-facing, meaning they are
meant to be displayed to the user in a user-friendly way. We expose these
through FastAPI exception handlers, which match the exception type.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    import httpx
    from pydantic_core import ValidationError

    from allama.executor.schemas import ExecutorActionErrorInfo
    from allama.registry.actions.schemas import RegistryActionValidationErrorInfo


class AllamaException(Exception):
    """Allama generic user-facing exception"""

    def __init__(self, *args, detail: Any | None = None, **kwargs):
        super().__init__(*args, **kwargs)
        self.detail = detail


class AllamaValidationError(AllamaException):
    """Allama user-facing validation error"""


class AllamaDSLError(AllamaValidationError):
    """Allama user-facing DSL error"""


class AllamaExpressionError(AllamaException):
    """Allama user-facing expression error"""


class AllamaCredentialsError(AllamaException):
    """Allama user-facing credentials error"""


class AllamaCredentialsNotFoundError(AllamaCredentialsError):
    """Allama user-facing credentials not found error"""


class AllamaAuthorizationError(AllamaException):
    """Allama user-facing authorization error"""


class AllamaManagementError(AllamaException):
    """Allama user-facing management error"""


class AllamaNotFoundError(AllamaException):
    """Raised when a resource is not found in the Allama database."""


class AllamaServiceError(AllamaException):
    """Allama generic user-facing service error"""


class RegistryError(AllamaException):
    """Generic exception raised when a registry error occurs."""


class RegistryActionError(RegistryError):
    """Exception raised when a registry action error occurs."""


class RegistryActionValidationError(AllamaException):
    """Exception raised when a registry action validation error occurs."""

    def __init__(
        self,
        *args,
        detail: dict[str, list[RegistryActionValidationErrorInfo]],
        **kwargs,
    ):
        super().__init__(*args, **kwargs)
        self.detail = detail


class RegistryValidationError(RegistryError):
    """Exception raised when a registry validation error occurs."""

    def __init__(
        self, *args, key: str | None = None, err: ValidationError | str | None = None
    ):
        super().__init__(*args)
        self.key = key
        self.err = err

    def __reduce__(self):
        return (self.__class__, (self.key, self.err))


class RegistryNotFound(RegistryError):
    """Exception raised when a registry is not found."""


class TaskUnreachable(AllamaException):
    """Raised when a task is unreachable."""


class ExecutorClientError(AllamaException):
    """Exception raised when an error occurs in the executor client."""


class ExecutionError(AllamaException):
    """Exception raised when an error occurs during action execution.
    Use this to wrap errors from the executor so that we should reraise"""

    def __init__(self, info: ExecutorActionErrorInfo):
        self.info = info
        # Build a user-friendly error message from the info
        message = (
            f"There was an error in the executor when calling action '{info.action_name}'."
            f"\n\n{info}"
        )
        super().__init__(message)


class LoopExecutionError(AllamaException):
    """Exception raised when an error occurs during loop execution."""

    def __init__(self, loop_errors: list[ExecutionError]):
        self.loop_errors = loop_errors
        n_errors = len(loop_errors)
        message = f"Loop execution failed with {n_errors} error(s)"
        super().__init__(message)


class AllamaSettingsError(AllamaException):
    """Exception raised when a setting error occurs."""


class AllamaImportError(AllamaException):
    """Exception raised when an import error occurs."""


class RateLimitExceeded(ExecutorClientError):
    """Exception raised when a request is rejected due to rate limiting."""

    def __init__(
        self,
        message: str = "Rate limit exceeded. Please try again later.",
        detail: Any = None,
        retry_after: int | None = None,
    ):
        """
        Initialize a rate limit exceeded error.

        Args:
            message: The error message
            detail: Additional error details
            retry_after: Suggested time in seconds to wait before retrying (if provided by the server)
        """
        super().__init__(message, detail)
        self.retry_after = retry_after

    @classmethod
    def from_response(
        cls, response: httpx.Response, detail: Any = None
    ) -> RateLimitExceeded:
        """
        Create a RateLimitExceededError from an HTTP response.

        Args:
            response: The HTTP response object
            detail: Additional error details

        Returns:
            A RateLimitExceededError instance
        """
        retry_after = None
        if "Retry-After" in response.headers:
            try:
                retry_after = int(response.headers["Retry-After"])
            except (ValueError, TypeError):
                pass

        message = "Rate limit exceeded. Please try again later."
        if retry_after:
            message += f" Server suggests waiting {retry_after} seconds."

        return cls(message, detail, retry_after)


class PayloadSizeExceeded(AllamaException):
    """Error raised when a payload exceeds a size limit."""


class EntitlementRequired(AllamaException):
    """Exception raised when a feature requires a higher subscription tier.

    Raised when an organization attempts to use a feature they are not entitled to.
    """

    def __init__(self, entitlement: str):
        self.entitlement = entitlement
        message = f"Feature '{entitlement}' requires a higher subscription tier"
        super().__init__(message, detail={"entitlement": entitlement})
