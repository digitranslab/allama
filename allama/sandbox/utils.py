"""Shared sandbox utilities.

Provides common utilities used by both Python script sandbox (allama/sandbox/)
and agent runtime sandbox (allama/agent/sandbox/).
"""

from __future__ import annotations

from pathlib import Path

from allama.config import (
    ALLAMA__DISABLE_NSJAIL,
    ALLAMA__SANDBOX_NSJAIL_PATH,
    ALLAMA__SANDBOX_ROOTFS_PATH,
)


def is_nsjail_available() -> bool:
    """Check if nsjail sandbox is available and configured.

    This function is used by both the Python script sandbox and the agent
    runtime sandbox to determine if nsjail isolation is available.

    Returns:
        True if nsjail can be used, False otherwise.
    """
    # Check the appropriate disable flag
    if ALLAMA__DISABLE_NSJAIL:
        return False

    nsjail_path = Path(ALLAMA__SANDBOX_NSJAIL_PATH)
    rootfs_path = Path(ALLAMA__SANDBOX_ROOTFS_PATH)

    return nsjail_path.exists() and rootfs_path.is_dir()
