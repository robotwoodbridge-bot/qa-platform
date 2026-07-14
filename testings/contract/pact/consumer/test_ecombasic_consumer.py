"""Consumer-driven contract tests for the EcomBasic API (rahulshettyacademy.com).

Happy-path only, mirroring the two scenarios already covered end-to-end in
testings/api/rest/tests/ecombasic_contract_test.robot:
  - POST /auth/login          — valid credentials
  - POST /order/create-order  — valid token + product id

Runs against a local Pact mock service instead of the real API and generates
../pacts/qa-platform-ecombasic-client-ecombasic-api.json. No provider
verification yet — rahulshettyacademy.com is a public demo site with no
provider-state test hooks to drive; see ../README.md.

The response shape asserted here is deliberately the same contract already
encoded in testings/api/rest/schemas/{login_response,create_order_response}.json
— this suite doesn't invent a new contract, just expresses the existing one
as a Pact interaction instead of a JSON Schema.
"""
from pact import EachLike, Term

from conftest import MOCK_BASE_URL
from ecombasic_client import create_order, login

VALID_EMAIL = "rbridge@gmail.com"
VALID_PASSWORD = "Rb123456"
VALID_PRODUCT_ID = "60d21b4667d0d8992e610c85"
NON_EMPTY_STRING = r"^\S+$"


def test_login_happy_path(pact):
    expected_body = {
        "message": "Login Successfully",
        "token": Term(NON_EMPTY_STRING, "abc123tokenvalue"),
        "userId": Term(NON_EMPTY_STRING, "5f9d1234abcd5e6f7890abcd"),
    }

    (
        pact.given("a registered EcomBasic user exists with valid credentials")
        .upon_receiving("a login request with valid credentials")
        .with_request(
            method="POST",
            path="/auth/login",
            headers={"Content-Type": "application/json"},
            body={"userEmail": VALID_EMAIL, "userPassword": VALID_PASSWORD},
        )
        .will_respond_with(200, body=expected_body)
    )

    with pact:
        response = login(VALID_EMAIL, VALID_PASSWORD, base_url=MOCK_BASE_URL)

    assert response.status_code == 200
    body = response.json()
    assert body["message"] == "Login Successfully"
    assert body["token"]
    assert body["userId"]


def test_create_order_happy_path(pact):
    auth_token = Term(NON_EMPTY_STRING, "abc123tokenvalue")
    expected_body = {
        "message": "Order Placed Successfully",
        "orders": EachLike(Term(NON_EMPTY_STRING, "a1b2c3d4e5f6"), minimum=1),
    }

    (
        pact.given("an authenticated user and a valid product id")
        .upon_receiving("a create-order request for a valid product")
        .with_request(
            method="POST",
            path="/order/create-order",
            headers={"Authorization": auth_token, "Content-Type": "application/json"},
            body={"orders": [{"country": "India", "productOrderedId": VALID_PRODUCT_ID}]},
        )
        .will_respond_with(201, body=expected_body)
    )

    with pact:
        response = create_order("abc123tokenvalue", VALID_PRODUCT_ID, base_url=MOCK_BASE_URL)

    assert response.status_code == 201
    body = response.json()
    assert body["message"] == "Order Placed Successfully"
    assert body["orders"]
    assert body["orders"][0]
