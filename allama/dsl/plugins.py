from __future__ import annotations

from pydantic.errors import PydanticUserError
from pydantic_ai.durable_exec.temporal import _workflow_runner
from pydantic_ai.exceptions import UserError
from temporalio.converter import DataConverter
from temporalio.plugin import SimplePlugin

from allama import config
from allama.dsl._converter import get_data_converter


class AllamaPydanticAIPlugin(SimplePlugin):
    """Pydantic AI plugin that preserves Allama's custom data converter.

    The upstream PydanticAIPlugin unconditionally replaces any non-default
    Temporal data converter with ``pydantic_data_converter``. This breaks
    Allama's custom ORJSON-based converter and causes unexpected behavior
    (e.g. treating defaulted fields as explicitly set).

    This plugin mirrors the upstream plugin's behavior (workflow runner and
    failure exception types) but delegates data converter selection to
    Allama's configuration, preserving any converter explicitly configured
    on the client.
    """

    def __init__(self) -> None:
        super().__init__(
            name="PydanticAIPlugin",
            data_converter=self._data_converter,
            workflow_runner=_workflow_runner,
            workflow_failure_exception_types=[UserError, PydanticUserError],
        )

    @staticmethod
    def _data_converter(converter: DataConverter | None) -> DataConverter:
        """Preserve existing converter or fall back to Allama's default."""
        if converter is not None:
            # Respect an explicitly configured data converter (e.g. Allama's)
            return converter

        # Fall back to Allama's custom data converter when none is provided
        return get_data_converter(
            compression_enabled=config.ALLAMA__CONTEXT_COMPRESSION_ENABLED
        )
