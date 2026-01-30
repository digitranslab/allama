from allama import config
from allama.feature_flags.enums import FeatureFlag

type FlagLike = FeatureFlag | str


def is_feature_enabled(flag: FlagLike) -> bool:
    """Check if a feature flag is enabled."""
    return flag in config.ALLAMA__FEATURE_FLAGS


__all__ = ["is_feature_enabled", "FeatureFlag"]
