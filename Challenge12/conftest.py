# conftest.py, auto-runs your RTL generator before any tests
# conftest.py
pytest_plugins = ["pytest_cocotb.plugin"]

import os
import pytest

@pytest.fixture(scope="session", autouse=True)
def generate_rtl():
    rv = os.system("python HW_Qvalue.py")
    if rv != 0 or not os.path.exists("q_update.v"):
        pytest.exit("Failed to generate RTL (q_update.v) via HW_Qvalue.py")

