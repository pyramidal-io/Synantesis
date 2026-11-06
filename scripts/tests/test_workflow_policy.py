"""Regression checks for credential and runner boundary escapes."""

import importlib.util
import tempfile
import unittest
from contextlib import chdir
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "workflow_policy", ROOT / "scripts/ci/check-workflows.py"
)
POLICY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(POLICY)


class WorkflowPolicyTest(unittest.TestCase):
    def validate(self, source):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "ci.yml"
            path.write_text(source)
            POLICY.validate(path)

    def test_accepts_current_isolated_workflow(self):
        self.validate((ROOT / ".forgejo/workflows/ci.yml").read_text())

    def test_yaml_workflows_are_also_inventoried(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "ci.yml").touch()
            (root / "extra.yaml").touch()
            self.assertEqual(
                POLICY.native_paths(root), [root / "ci.yml", root / "extra.yaml"]
            )

    def test_main_rejects_an_additional_yaml_workflow(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            workflows = root / ".forgejo/workflows"
            workflows.mkdir(parents=True)
            (workflows / "ci.yml").write_text(
                (ROOT / ".forgejo/workflows/ci.yml").read_text()
            )
            (workflows / "extra.yaml").write_text(
                "name: Unexpected\non: push\njobs:\n"
                "  extra:\n    runs-on: forgejo-trusted-control-v1\n"
                "    steps:\n      - run: echo unexpected\n"
            )
            with (
                chdir(root),
                self.assertRaisesRegex(SystemExit, "only candidate workflow"),
            ):
                POLICY.main()

    def test_published_github_workflows_are_upstream_only(self):
        import yaml

        for path in (ROOT / ".github/workflows").glob("*.yml"):
            workflow = yaml.load(path.read_text(), Loader=yaml.BaseLoader)
            for job in workflow["jobs"].values():
                self.assertTrue(
                    job.get("if", "").startswith(
                        "github.repository == 'Tymeslot/tymeslot' &&"
                    ),
                    str(path),
                )

    def test_rejects_credentials_trusted_runners_and_published_service_ports(self):
        source = (ROOT / ".forgejo/workflows/ci.yml").read_text()
        for altered in (
            source.replace("forgejo-untrusted-pr-v1", "forgejo-trusted-control-v1"),
            source.replace("MIX_ENV: test", "MIX_ENV: ${{ secrets.TOKEN }}"),
            source.replace("MIX_ENV: test", "MIX_ENV: ${{ github.token }}"),
            source.replace("MIX_ENV: test", "MIX_ENV: ${{ secrets['TOKEN'] }}"),
            source.replace("MIX_ENV: test", "MIX_ENV: ${{ github['token'] }}"),
            source.replace("MIX_ENV: test", "MIX_ENV: ${{ toJSON(github) }}"),
            source.replace("MIX_ENV: test", "MIX_ENV: ${{ toJSON(secrets) }}"),
            source.replace(
                "POSTGRES_PASSWORD: postgres",
                "POSTGRES_PASSWORD: postgres\n        ports: ['5432:5432']",
            ),
            source.replace("persist-credentials: false", "persist-credentials: true"),
            source.replace("pull_request:", "pull_request_target:"),
            source.replace("name: Verify", "name: Disabled"),
            source.replace(
                "- name: Run application gates",
                "- if: github['token']\n        name: Run application gates",
            ),
        ):
            with self.subTest(altered=altered), self.assertRaises(ValueError):
                self.validate(altered)


if __name__ == "__main__":
    unittest.main()
