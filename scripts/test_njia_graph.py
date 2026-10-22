#!/usr/bin/env python3
"""Checks spec/njia-graph.json against itself and against spec/routes.json: run
`python3 scripts/test_njia_graph.py`."""

from __future__ import annotations

import io
import json
import os
import unittest

SPEC = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "spec")

# The run's full-screen form has a link of its own and no row in routes.json, where `sdkFlow`'s
# presentation is "push | fullScreen".
FULL_SCREEN_RUN = {"sdkFlowFullScreen": "sdkFlow"}


def load(name: str):
    with io.open(os.path.join(SPEC, name), encoding="utf-8") as handle:
        return json.load(handle)


def steps(nodes: list) -> list[dict]:
    """Every step in the graph, a tab group's tabs included."""
    found = []
    for node in nodes:
        found.extend(steps(node["steps"]) if "steps" in node else [node])
    return found


class NjiaGraphTest(unittest.TestCase):
    def setUp(self) -> None:
        self.steps = steps(load("njia-graph.json")["nodes"])
        self.ids = [step["step"] for step in self.steps]
        self.routes = load("routes.json")["routes"]

    def test_step_ids_are_unique(self) -> None:
        self.assertEqual(sorted(self.ids), sorted(set(self.ids)))

    def test_every_go_target_is_a_step(self) -> None:
        for step in self.steps:
            for target in step.get("to", []):
                self.assertIn(target, self.ids, f"{step['step']} goes to {target}")

    def test_links_are_unique(self) -> None:
        links = [step["link"] for step in self.steps if "link" in step]
        self.assertEqual(sorted(links), sorted(set(links)))

    def test_every_route_is_a_step_linked_at_its_path(self) -> None:
        links = {step["step"]: step.get("link") for step in self.steps}
        for route in self.routes:
            self.assertIn(route["id"], links, f"route {route['id']} has no step")
            self.assertEqual(links[route["id"]], route["path"].lstrip("/"), f"route {route['id']}")

    def test_every_linked_step_is_a_route(self) -> None:
        routes = {route["id"] for route in self.routes}
        for step in self.steps:
            if "link" in step:
                self.assertIn(FULL_SCREEN_RUN.get(step["step"], step["step"]), routes, step["step"])


if __name__ == "__main__":
    unittest.main()
