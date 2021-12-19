from eth2spec.test.context import (
    spec_state_test,
    with_phases,
)
from eth2spec.test.helpers.constants import ALTAIR


@with_phases([ALTAIR])
@spec_state_test
def test_weight_denominator(spec, state):
    assert (
        spec.TIMELY_HEAD_WEIGHT
        + spec.TIMELY_SOURCE_WEIGHT
        + spec.TIMELY_TARGET_WEIGHT
        + spec.SYNC_REWARD_WEIGHT
        + spec.PROPOSER_WEIGHT
    ) == spec.WEIGHT_DENOMINATOR


@with_phases([ALTAIR])
@spec_state_test
def test_inactivity_score(spec, state):
    assert spec.config.INACTIVITY_SCORE_BIAS <= spec.config.INACTIVITY_SCORE_RECOVERY_RATE
