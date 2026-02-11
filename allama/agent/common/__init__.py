"""Lightweight shared module for agent sandbox communication.

This module provides types and utilities for orchestrator-runtime communication
with minimal dependencies. It is designed to be imported by the sandbox entrypoint
without pulling in heavy allama modules.

Key design principles:
- No imports from allama.config (reads os.environ directly)
- Pure dataclasses instead of Pydantic models
- orjson for serialization (no pydantic_core)
"""

from allama.agent.common.adapter_base import BaseHarnessAdapter
from allama.agent.common.config import (
    ALLAMA__AGENT_SANDBOX_MEMORY_MB,
    ALLAMA__AGENT_SANDBOX_TIMEOUT,
    ALLAMA__DISABLE_NSJAIL,
    JAILED_CONTROL_SOCKET_PATH,
    JAILED_LLM_SOCKET_PATH,
)
from allama.agent.common.exceptions import (
    AgentSandboxError,
    AgentSandboxExecutionError,
    AgentSandboxTimeoutError,
    AgentSandboxValidationError,
)
from allama.agent.common.protocol import (
    RuntimeEventEnvelope,
    RuntimeInitPayload,
)
from allama.agent.common.socket_io import (
    HEADER_SIZE,
    MAX_PAYLOAD_SIZE,
    MessageType,
    SocketStreamWriter,
    build_message,
    read_message,
)
from allama.agent.common.stream_types import (
    HarnessType,
    StreamEventType,
    ToolCallContent,
    UnifiedStreamEvent,
)
from allama.agent.common.types import (
    MCPServerConfig,
    MCPToolDefinition,
    SandboxAgentConfig,
)

__all__ = [
    # Adapter base
    "BaseHarnessAdapter",
    # Config
    "JAILED_CONTROL_SOCKET_PATH",
    "JAILED_LLM_SOCKET_PATH",
    "ALLAMA__AGENT_SANDBOX_MEMORY_MB",
    "ALLAMA__AGENT_SANDBOX_TIMEOUT",
    "ALLAMA__DISABLE_NSJAIL",
    # Exceptions
    "AgentSandboxError",
    "AgentSandboxExecutionError",
    "AgentSandboxTimeoutError",
    "AgentSandboxValidationError",
    # Protocol
    "RuntimeEventEnvelope",
    "RuntimeInitPayload",
    # Socket I/O
    "HEADER_SIZE",
    "MAX_PAYLOAD_SIZE",
    "MessageType",
    "SocketStreamWriter",
    "build_message",
    "read_message",
    # Stream types
    "HarnessType",
    "StreamEventType",
    "ToolCallContent",
    "UnifiedStreamEvent",
    # Types
    "MCPServerConfig",
    "MCPToolDefinition",
    "SandboxAgentConfig",
]
