# precommitr

> Shared pre-commit hooks for R analysts. One install, one command, every repo.

`precommitr` is a tiny R package that bundles **one** opinionated
`.pre-commit-config.yaml` and exposes **one** function to drop it into any of
your repos and activate the git hooks. The goal: every analyst in the team
runs the same checks (styler, lintr, parsable-R, no-browser/print/debug,
trailing-whitespace, EOF, large-file guard) before each commit, without anyone
having to remember the YAML.

---

## How it works

```
+----------------------+        install once         +----------------------+
| precommitr R package |  ---------------------->    |  Each analyst's      |
| (this repo)          |     remotes::install_*      |  R installation      |
+----------+-----------+                             +----------+-----------+
           |                                                    |
           | bundles inst/templates/pre-commit-config.yaml      |
           |                                                    | use_precommits()
           v                                                    v
   .pre-commit-config.yaml  ------ copied into ------>  any analyst repo
                                                                |
                                                                | git commit
                                                                v
                                                       styler / lintr / etc.
```

There is exactly **one** source of truth: the YAML inside this package. To
roll out a change org-wide, edit it here, bump the package version, and ask
the team to upgrade.

---

## One-time setup (per analyst, per machine)

```r
# 1. Install the wrapper package
install.packages("remotes")
remotes::install_github("quinten/r-package-precommits", ref = "development")

# 2. Install the pre-commit framework itself (Python tool; one time per machine)
precommitr::install_precommit()
```

After this, the analyst never has to think about it again.

---

## Per-repo setup (every new project)

```r
# from the repo's working directory
precommitr::use_precommits()
```

That single line:

1. Copies the shared `.pre-commit-config.yaml` into the repo root.
2. Runs `pre-commit install` so the hooks fire on every `git commit`.

From now on, every commit in that repo is checked. If a hook fails (e.g. a
file isn't styled), the commit is blocked, the hook fixes the file, and the
analyst just `git add`s the fix and commits again.

---

## Updating the org config

When you want everyone to pick up a new version of the hooks:

1. Edit `inst/templates/pre-commit-config.yaml` in this repo.
2. Bump the `Version:` in `DESCRIPTION`.
3. Merge into `main` (or `development`).
4. Tell analysts:

   ```r
   remotes::install_github("quinten/r-package-precommits")
   precommitr::update_precommits()   # re-copies the YAML, refreshes hooks
   ```

---

## What's in the shared config

| Hook                       | What it does                                        |
| -------------------------- | --------------------------------------------------- |
| `style-files`              | Auto-formats R code with **styler** (tidyverse)     |
| `lintr`                    | Runs **lintr** (warn-only, won't block commits)     |
| `parsable-R`               | Fails if any `.R` file can't be parsed              |
| `no-browser-statement`     | Blocks leftover `browser()` calls                   |
| `no-debug-statement`       | Blocks leftover `debug()` / `debugonce()` calls     |
| `no-print-statement`       | Blocks leftover `print()` calls in scripts          |
| `readme-rmd-rendered`      | Reminds you to re-knit `README.Rmd` if it changed   |
| `use-tidy-description`     | Keeps `DESCRIPTION` files tidy                      |
| `trailing-whitespace`      | Strips trailing whitespace                          |
| `end-of-file-fixer`        | Ensures every file ends with a newline              |
| `check-added-large-files`  | Blocks accidental commits of files > 2 MB           |
| `check-merge-conflict`     | Catches leftover `<<<<<<<` markers                  |
| `check-yaml`               | Validates YAML files                                |
| `mixed-line-ending`        | Normalises line endings to LF                       |

---

## Function reference

| Function                          | What it does                                       |
| --------------------------------- | -------------------------------------------------- |
| `install_precommit()`             | One-time install of the `pre-commit` framework     |
| `use_precommits()`                | Drop the shared config + activate hooks in a repo  |
| `update_precommits()`             | Re-copy the latest shared config into a repo       |
| `check_precommit_install()`       | Is the `pre-commit` executable on PATH?            |

---

## FAQ

**Q: An analyst doesn't have Python installed. Will this work?**
`precommitr::install_precommit()` will set up an isolated conda env via the
upstream `precommit` R package. They don't need to manage Python themselves.

**Q: Can analysts override hooks locally?**
Yes — they can edit the local `.pre-commit-config.yaml`, but the next
`update_precommits()` will overwrite it. Discourage per-repo drift; raise an
issue on this repo instead so the change gets picked up org-wide.

**Q: What if a hook is too strict on an existing codebase?**
Open a PR on this repo to relax the hook (e.g. add `--warn_only` or scope it
with `files:` / `exclude:`). Don't fork the config per repo.
