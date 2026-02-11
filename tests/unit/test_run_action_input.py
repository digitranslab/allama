import uuid
from datetime import UTC, datetime

from allama.dsl.schemas import ActionStatement, RunActionInput, RunContext
from allama.expressions.common import ExprContext
from allama.identifiers.workflow import ExecutionUUID, WorkflowUUID
from allama.registry.lock.types import RegistryLock


def test_run_action_input_drops_legacy_inputs_context():
    wf_id = WorkflowUUID.new_uuid4()
    exec_id = ExecutionUUID.new_uuid4()
    action_name = "core.transform.reshape"
    run_input = RunActionInput(
        task=ActionStatement(
            action=action_name,
            args={"value": 1},
            ref="reshape",
        ),
        exec_context={
            "INPUTS": {"legacy": True},  # pyright: ignore[reportArgumentType]
            ExprContext.ACTIONS: {},
            ExprContext.TRIGGER: None,
            ExprContext.ENV: {},
        },
        run_context=RunContext(
            wf_id=wf_id,
            wf_exec_id=f"{wf_id.short()}/{exec_id.short()}",
            wf_run_id=uuid.uuid4(),
            environment="test",
            logical_time=datetime.now(UTC),
        ),
        registry_lock=RegistryLock(
            origins={"allama_registry": "test-version"},
            actions={action_name: "allama_registry"},
        ),
    )

    assert "INPUTS" not in run_input.exec_context
    assert ExprContext.ACTIONS in run_input.exec_context
