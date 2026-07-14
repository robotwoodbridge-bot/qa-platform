"""Minimal EcomBasic API client — the "consumer" whose contract is under test.

Same two endpoints, request shapes, and auth handling as
testings/api/rest/resources/api_keywords.robot's `POST Ecom Login` and
`POST Ecom Create Order` keywords, ported to plain Python so Pact can point
it at the mock service instead of the real API.
"""
import requests

DEFAULT_BASE_URL = "https://rahulshettyacademy.com/api/ecom"


def login(email: str, password: str, base_url: str = DEFAULT_BASE_URL) -> requests.Response:
    """Authenticate and return the full response object."""
    return requests.post(
        f"{base_url}/auth/login",
        json={"userEmail": email, "userPassword": password},
        headers={"Content-Type": "application/json"},
        timeout=10,
    )


def create_order(
    token: str,
    product_id: str,
    base_url: str = DEFAULT_BASE_URL,
    country: str = "India",
) -> requests.Response:
    """Place an order and return the full response object."""
    return requests.post(
        f"{base_url}/order/create-order",
        json={"orders": [{"country": country, "productOrderedId": product_id}]},
        headers={"Authorization": token, "Content-Type": "application/json"},
        timeout=10,
    )
