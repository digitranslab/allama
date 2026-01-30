from __future__ import annotations

from dataclasses import dataclass

from allama.dsl.types import ActionErrorInfo
from allama.identifiers import WorkflowExecutionID, WorkflowID
from allama.workflow.executions.enums import TriggerType


@dataclass(frozen=True)
class ErrorHandlerWorkflowInput:
    message: str
    handler_wf_id: WorkflowID
    orig_wf_id: WorkflowID
    orig_wf_exec_id: WorkflowExecutionID
    orig_wf_title: str
    trigger_type: TriggerType
    errors: list[ActionErrorInfo] | None = None
    orig_wf_exec_url: str | None = None
