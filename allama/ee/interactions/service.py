# Shim for EE service - requires EE installation
try:
    from allama_ee.interactions.service import *  # noqa: F401,F403  # pyright: ignore[reportWildcardImportFromLibrary]
except ImportError as exc:
    raise ImportError(
        "Allama Enterprise features are not installed. "
        "Install with extras: `pip install 'allama[ee]'`."
    ) from exc
