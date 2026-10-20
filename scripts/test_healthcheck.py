#!/usr/bin/env python3
"""Tests for healthcheck.py."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).parent))

import healthcheck  # noqa: E402


def _mock_response(status: int = 200) -> mock.MagicMock:
    """Mock that behaves like urllib's context-manager response."""
    m = mock.MagicMock()
    m.status = status
    m.__enter__ = mock.Mock(return_value=m)
    m.__exit__ = mock.Mock(return_value=False)
    return m


class TestParseServices(unittest.TestCase):
    def test_single(self) -> None:
        result = healthcheck._parse_services("a=http://x")
        self.assertEqual(result, [("a", "http://x")])

    def test_multiple(self) -> None:
        result = healthcheck._parse_services("a=http://x,b=http://y")
        self.assertEqual(result, [("a", "http://x"), ("b", "http://y")])

    def test_invalid_raises(self) -> None:
        with self.assertRaises(Exception):
            healthcheck._parse_services("invalid")


class TestCheckService(unittest.TestCase):
    def test_ok(self) -> None:
        with mock.patch("urllib.request.urlopen", return_value=_mock_response(200)):
            r = healthcheck.check_service("a", "http://x", 1.0, retries=0)
        self.assertTrue(r["ok"])
        self.assertEqual(r["status"], 200)
        self.assertEqual(r["attempts"], 1)

    def test_5xx_fails(self) -> None:
        with mock.patch("urllib.request.urlopen", return_value=_mock_response(503)):
            r = healthcheck.check_service("a", "http://x", 1.0, retries=0)
        self.assertFalse(r["ok"])
        self.assertEqual(r["status"], 503)

    def test_retries_then_succeeds(self) -> None:
        side_effect = [urllib_error(), _mock_response(200)]
        with mock.patch("urllib.request.urlopen", side_effect=side_effect):
            r = healthcheck.check_service("a", "http://x", 1.0, retries=1)
        self.assertTrue(r["ok"])
        self.assertEqual(r["attempts"], 2)


def urllib_error() -> Exception:
    import urllib.error
    return urllib.error.URLError("connection refused")


if __name__ == "__main__":
    unittest.main()
