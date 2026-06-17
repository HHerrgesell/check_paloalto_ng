# Releasing

Releases are cut locally with [python-semantic-release]; the version bump,
commit, tag, build and PyPI upload all run locally, so no token is stored in CI.
GitHub Actions (`.github/workflows/tests.yml`) only runs the test matrix.

No GitHub *Release* objects are created and nothing is pushed automatically: the
release command runs with `--no-vcs-release` (so no `GH_TOKEN` is required) and
`--no-push` (the push is a separate, manual step after reviewing the result).

## Versioning

The version is computed automatically from the commit messages since the last
`vX.Y.Z` tag, following [Conventional Commits]:

| Commit prefix                  | Bump          |
| ------------------------------ | ------------- |
| `fix:` / `perf:`               | patch (0.8.1 → 0.8.2) |
| `feat:`                        | minor (0.8.1 → 0.9.0) |
| `feat!:` / `BREAKING CHANGE:`  | minor while in 0.x (see note) |
| `chore:`/`ci:`/`docs:`/`build:`/`refactor:`/`style:`/`test:` | no release |

The single source of truth for the version is `check_pa/__init__.py`; `setup.cfg`
derives it via `attr:`. Semantic-release bumps `__init__.py`, updates
`CHANGELOG.md` (above the `<!-- version list -->` marker), commits and tags.

> Note: this project stays in the `0.x` series (`allow_zero_version = true`,
> `major_on_zero = false`), so breaking changes bump the minor, not to `1.0.0`.
> To deliberately release `1.0.0`, set `major_on_zero = true` in
> `pyproject.toml` for that release.

## One-time setup

Install the release tools into a virtual environment (do not install globally):

```bash
python -m venv .venv
.venv/bin/pip install python-semantic-release build twine
```

Activate it (`source .venv/bin/activate`) before running the release commands
below, or call the tools via `.venv/bin/...`. Alternatively, install the CLIs in
isolation with `pipx install python-semantic-release` and `pipx install twine`.

PyPI credentials are read from `~/.pypirc` (or a configured keyring).

## Cutting a release

The recommended path is the gate script, which refuses to release unless the
tree is clean, the branch is `main`, the tests pass, and (if `gh` is available)
the latest CI run is green:

```bash
./scripts/release.sh
```

It bumps the version, updates `CHANGELOG.md`, commits and tags, and builds
`dist/` — without pushing and without creating a GitHub release. After
reviewing the result, finish manually:

```bash
git push origin main --follow-tags     # push the release commit and tag
twine upload dist/*                     # upload to PyPI
```

The equivalent without the gate script:

```bash
semantic-release version --no-push --no-vcs-release
git push origin main --follow-tags
twine upload dist/*
```

Preview the next release without changing anything:

```bash
semantic-release version --print            # print the next version only
semantic-release version --noop -v          # full dry run, no writes
```

## Optional: GitHub Release

GitHub Release objects are not created by the steps above. To add one for a tag,
use the GitHub CLI, which uses its own stored login (no token in the environment):

```bash
gh release create vX.Y.Z --title vX.Y.Z --generate-notes dist/check_paloalto_ng-X.Y.Z*
```

`--generate-notes` lets GitHub build the notes; use `--notes "..."` or
`--notes-file <file>` to supply them. If an invalid `GH_TOKEN` is exported in the
shell it shadows the CLI login and the API returns HTTP 401 — unset it first
(`unset GH_TOKEN`). Alternatively, let semantic-release create the release during
the version step by providing a valid token from the CLI login:
`GH_TOKEN=$(gh auth token) semantic-release version`.

[python-semantic-release]: https://python-semantic-release.readthedocs.io/
[Conventional Commits]: https://www.conventionalcommits.org/
