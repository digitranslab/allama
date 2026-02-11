"""Sandboxed agent runtime utilities.

This package provides NSJail spawning utilities and config for running
agent runtimes in isolated sandboxes.

Import directly from submodules:
- allama.agent.sandbox.config: AgentSandboxConfig, AgentResourceLimits
- allama.agent.sandbox.nsjail: spawn_jailed_runtime, etc.
- allama.agent.sandbox.entrypoint: CLI entrypoint for sandboxed runtime
- allama.agent.sandbox.llm_bridge: HTTP bridge for LLM socket

Note: This __init__.py is intentionally minimal to allow the sandbox
entrypoint to import without pulling in heavy dependencies like
allama.config (which is not mounted in the sandbox).
"""
