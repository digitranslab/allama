"""Registry test configuration.

This conftest.py enables feature flags needed for EE UDF tests.
The flags must be added to config.ALLAMA__FEATURE_FLAGS BEFORE
allama.api.app is imported, because internal_router.py conditionally
includes task_router/duration_router at import time based on is_feature_enabled().
"""

from allama import config
from allama.feature_flags.enums import FeatureFlag

# Add EE feature flags needed for tests.
# This must happen before allama.api.app is imported (which happens in test files).
# The root conftest.py imports from allama.config but NOT from allama.api.app,
# so this modification happens before internal_router.py is loaded.
config.ALLAMA__FEATURE_FLAGS.add(FeatureFlag.CASE_TASKS)
config.ALLAMA__FEATURE_FLAGS.add(FeatureFlag.CASE_DURATIONS)
