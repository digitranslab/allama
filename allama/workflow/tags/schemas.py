from pydantic import BaseModel

from allama.identifiers import TagID


class WorkflowTagCreate(BaseModel):
    tag_id: TagID
