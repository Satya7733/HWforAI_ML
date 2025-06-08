import cocotb
from cocotb.triggers import RisingEdge, Timer

async def clock_gen(clk):
    while True:
        clk.value = 0
        await Timer(5, units="ns")
        clk.value = 1
        await Timer(5, units="ns")

async def hw_scalar_mult(k: int, Px: int, Py: int, dut) -> tuple:
    # Ensure clock is running
    cocotb.start_soon(clock_gen(dut.clk))

    # Reset sequence
    dut.rst_n.value = 0
    for _ in range(2): await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(2): await RisingEdge(dut.clk)

    # Apply inputs
    dut.k.value = k
    dut.Px.value = Px
    dut.Py.value = Py
    dut.Pinf.value = 0  # Assuming point is not at infinity
    dut.start.value = 1

    await RisingEdge(dut.clk)
    dut.start.value = 0

    # Wait for done signal
    while dut.done.value != 1:
        await RisingEdge(dut.clk)

    # Read outputs
    X = int(dut.Xout.value)
    Y = int(dut.Yout.value)
    inf = int(dut.inf_out.value)

    if inf:
        raise ValueError("Output point is at infinity")

    return (X, Y)
