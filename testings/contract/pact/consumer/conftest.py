import os

import pytest
from pact import Consumer, Provider

PACT_MOCK_HOST = "localhost"
PACT_MOCK_PORT = 1234
PACT_DIR = os.path.join(os.path.dirname(__file__), "..", "pacts")

MOCK_BASE_URL = f"http://{PACT_MOCK_HOST}:{PACT_MOCK_PORT}"


@pytest.fixture(scope="session")
def pact():
    service = Consumer("qa-platform-ecombasic-client").has_pact_with(
        Provider("ecombasic-api"),
        host_name=PACT_MOCK_HOST,
        port=PACT_MOCK_PORT,
        pact_dir=PACT_DIR,
    )
    service.start_service()
    yield service
    service.stop_service()
