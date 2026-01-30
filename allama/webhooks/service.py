from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from allama.db.models import Webhook
from allama.identifiers import WorkflowID


async def get_webhook(
    session: AsyncSession,
    workspace_id,
    workflow_id: WorkflowID,
) -> Webhook | None:
    statement = select(Webhook).where(
        Webhook.workspace_id == workspace_id,
        Webhook.workflow_id == workflow_id,
    )
    result = await session.execute(statement)
    return result.scalars().first()
