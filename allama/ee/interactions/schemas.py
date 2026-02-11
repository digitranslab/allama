# Shim to re-export core models for backward compatibility
from allama.interactions.schemas import *  # noqa: F401,F403

# EE-specific models are re-exported from allama_ee when available
try:
    from allama_ee.interactions.service import (  # noqa: F401
        CreateInteractionActivityInputs as CreateInteractionActivityInputs,
    )
    from allama_ee.interactions.service import (
        InteractionCreate as InteractionCreate,
    )
    from allama_ee.interactions.service import (
        InteractionRead as InteractionRead,
    )
    from allama_ee.interactions.service import (
        InteractionUpdate as InteractionUpdate,
    )
    from allama_ee.interactions.service import (
        UpdateInteractionActivityInputs as UpdateInteractionActivityInputs,
    )
except ImportError:
    # If EE is not installed, these models won't be available
    # This is expected for OSS-only installations
    pass
