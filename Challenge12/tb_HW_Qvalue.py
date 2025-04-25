# tb_HW_Qvalue.py
import random
import cocotb
from cocotb.triggers import Timer
from cocotb.result import TestFailure as COCOTBTestFailure

@cocotb.test()
async def test_q_update_basic(dut):
    """Test q_update.v with a handful of small-integer vectors."""
    # give combinational logic a moment
    await Timer(1, units='ns')

    for i in range(10):
        # small ints to avoid wrap
        q_sa    = random.randint(0, 100)
        q_s2max = random.randint(0, 100)
        reward  = random.randint(0, 50)
        gamma   = random.randint(0, 5)
        alpha   = random.randint(0, 5)

        dut.q_sa   .value = q_sa
        dut.q_s2max.value = q_s2max
        dut.reward .value = reward
        dut.gamma  .value = gamma
        dut.alpha  .value = alpha

        await Timer(1, units='ns')

        got = int(dut.q_out.value)
        # golden model
        delta  = reward + gamma*q_s2max - q_sa
        golden = q_sa + alpha*delta

        if got != golden:
            raise COCOTBTestFailure(
                f"Vector #{i}: "
                f"q_sa={q_sa}, q_s2max={q_s2max}, reward={reward}, "
                f"gamma={gamma}, alpha={alpha} → got {got}, expected {golden}"
            )

    dut._log.info("✅ All 10 integer test vectors passed!")
