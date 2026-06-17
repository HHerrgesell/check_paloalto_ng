# Releasing

Releases are cut locally with [python-semantic-release]; the PyPI upload runs
from the developer machine, so no token is stored in CI. GitHub Actions
(`.github/workflows/tests.yml`) only runs the test matrix.

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

```bash
pip install python-semantic-release build twine
```

PyPI credentials are read from `~/.pypirc` (or a configured keyring).

## Cutting a release

From a clean, up-to-date `main`:

```bash
# 1. Bump version, update CHANGELOG, commit, tag, and build dist/ — all local.
semantic-release version

# 2. Push the release commit and tag.
git push origin main --follow-tags

# 3. Upload the built artifacts to PyPI.
twine upload dist/*
```

Preview the next release without changing anything:

```bash
semantic-release version --print            # print the next version only
semantic-release version --noop -v          # full dry run, no writes
```

Optionally attach the built artifacts to a GitHub Release as well (requires a
`GH_TOKEN` in the environment):

```bash
semantic-release publish
```

[python-semantic-release]: https://python-semantic-release.readthedocs.io/
[Conventional Commits]: https://www.conventionalcommits.org/
