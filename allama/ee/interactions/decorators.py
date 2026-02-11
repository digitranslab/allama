# Shim for EE decorators with no-op fallback
try:
    from allama_ee.interactions.decorators import (
        maybe_interactive as maybe_interactive,
    )
except ImportError:
    # Provide a no-op fallback when EE is not installed
    from collections.abc import Awaitable, Callable

    from allama.dsl.schemas import TaskResult

    def maybe_interactive(
        func: Callable[..., Awaitable[TaskResult]],
    ) -> Callable[..., Awaitable[TaskResult]]:
        """No-op decorator when EE is not installed."""
        return func


__all__ = ["maybe_interactive"]
