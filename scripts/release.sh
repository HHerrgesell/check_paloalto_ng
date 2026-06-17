#!/usr/bin/env bash
#
# Release gate: refuses to cut a release unless the tree is clean, on the
# default branch, the test suite passes, and (if gh is available) the CI run for
# the exact HEAD commit is green. On success it runs semantic-release locally
# WITHOUT pushing and WITHOUT creating a GitHub release; the push and the PyPI
# upload remain explicit manual steps (see RELEASING.md).
set -euo pipefail

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
DEFAULT_BRANCH="main"

if [ "$BRANCH" != "$DEFAULT_BRANCH" ]; then
    echo "ERROR: releases are cut from '$DEFAULT_BRANCH', current branch is '$BRANCH'." >&2
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "ERROR: working tree is not clean. Commit or stash changes first." >&2
    exit 1
fi

echo ">> Running the test suite..."
PYTHONPATH=.:tests pytest tests/ -q

# Optional: refuse if the CI run for the exact HEAD commit did not succeed.
# Matching the HEAD SHA (instead of the latest branch run) avoids passing the
# gate on an older commit's green run.
if command -v gh >/dev/null 2>&1; then
    HEAD_SHA="$(git rev-parse HEAD)"
    echo ">> Checking CI run for HEAD ($HEAD_SHA)..."
    CONCLUSION="$(gh run list --branch "$BRANCH" --limit 20 \
        --json headSha,conclusion \
        --jq "[.[] | select(.headSha==\"$HEAD_SHA\")][0].conclusion" 2>/dev/null || true)"
    if [ -z "$CONCLUSION" ]; then
        echo ">> WARNING: no CI run found for HEAD yet; relying on the local test run above."
    elif [ "$CONCLUSION" != "success" ]; then
        echo "ERROR: CI run for HEAD concluded '$CONCLUSION', not 'success'." >&2
        exit 1
    fi
fi

echo ">> Tests green. Bumping version locally (no push, no GitHub release)..."
semantic-release version --no-push --no-vcs-release

echo
echo "Done. Review the result, then finish the release manually:"
echo "  git push origin $DEFAULT_BRANCH --follow-tags"
echo "  twine upload dist/*"
echo "  # optional GitHub release: gh release create <tag> --generate-notes dist/*"
