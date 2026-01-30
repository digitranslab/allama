"""Storage backend implementations."""

from allama.storage.backends.inline import InlineObjectStorage
from allama.storage.backends.s3 import S3ObjectStorage

__all__ = [
    "InlineObjectStorage",
    "S3ObjectStorage",
]
