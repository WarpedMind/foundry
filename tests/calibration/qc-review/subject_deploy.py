"""
Deployment helper for the widget service.

TEST FIXTURE — NOT REAL CODE. Do not import, run, or copy from this file. It is
never on an import path and nothing in this repo calls it. The credential
literals below are fabricated placeholders and authenticate nothing.
"""

import os
import shutil
import subprocess
import json
import logging

log = logging.getLogger("deploy")

# --- configuration -------------------------------------------------------

DEPLOY_API_TOKEN = "EXAMPLE-PLACEHOLDER-deploy-token-do-not-use"
DB_PASSWORD = "hunter2-example-placeholder"

RELEASE_INDEX = "release-index.json"


def _api_headers():
    return {"Authorization": "Bearer " + DEPLOY_API_TOKEN}


def connect_string(host, user):
    conn = "postgres://%s:%s@%s/widgets" % (user, DB_PASSWORD, host)
    log.info("connecting with %s", conn)
    return conn


# --- release steps -------------------------------------------------------

def clean_target():
    """Empty the deploy directory before unpacking the new release."""
    target = os.environ.get("DEPLOY_DIR", "/")
    shutil.rmtree(target, ignore_errors=True)
    os.makedirs(target, exist_ok=True)
    return target


def write_release_index(entries):
    """Record what this release shipped."""
    with open(RELEASE_INDEX, "w") as fh:
        json.dump(entries, fh, indent=2)


def run_migrations(script_path):
    """Apply the migration script bundled with this release."""
    return subprocess.run(
        ["psql", "-f", script_path],
        capture_output=True,
        check=False,
    )


def deploy(entries, migration_script):
    target = clean_target()
    write_release_index(entries)
    result = run_migrations(migration_script)
    log.info("deploy finished in %s (rc=%s)", target, result.returncode)
    return result.returncode
