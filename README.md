# precommitr

> Shared pre-commit hooks for R analysts. One install, one command, every repo
> — **and zero network access at hook time**.

`precommitr` is a tiny R package that bundles **one** opinionated
`.pre-commit-config.yaml` and exposes **one** function to drop it into any of
your repos and activate the git hooks. Every hook is `repo: local` and runs
through `precommitr::run_hook()`, which means pre-commit never has to clone
external hook repos from GitHub — once `precommitr` is installed in R, the
hooks work fully **offline**. Ideal for analyst VMs where outbound network
access is whitelisted.

---

## How it works

```
+----------------------+        install once         +----------------------+
| precommitr R package |  ---------------------->    |  Each analyst's      |
| (this repo)          |     remotes::install_*      |  R installation      |
+----------+-----------+        or internal mirror   +----------+-----------+
           |                                                    |
           | bundles inst/templates/pre-commit-config.yaml      |
           |  (all hooks: repo: local, no upstream cloning)     | use_precommits()
           v                                                    v
   .pre-commit-config.yaml  ------ copied into ------>  any analyst repo
                                                                |
                                                                | git commit
                                                                v
                              pre-commit  ->  Rscript --no-init-file -e
                                              'precommitr::run_hook(...)'
```

The single source of truth is the YAML inside this package **plus** the hook
implementations in `R/hooks.R`. To roll out a change org-wide, edit either,
bump the package version, ask the team to upgrade.

---

## One-time setup (per analyst, per machine)

```r
# 1. Install the wrapper package — from GitHub, or from your internal mirror
install.packages("remotes")
remotes::install_github("QuintenSand/r-package-precommits", ref = "development")
#   ...or, if your org has a CRAN-like mirror:
# install.packages("precommitr", repos = "https://your.internal/mirror")

# 2. Make sure the 'pre-commit' binary is on PATH:
precommitr::install_precommit()
# If you have no internet, do one of:
#   pip install --user pre-commit
#   pipx install pre-commit
#   conda install -c conda-forge pre-commit
```

### Note on `renv`

Hooks are invoked with `Rscript --no-init-file`, which bypasses the project's
`.Rprofile` (and thus `renv` auto-activation). This is deliberate — it means
the hooks always use the **user library**, not the per-project renv library.
Install `precommitr` into the user library:

```r
# from a fresh R session (no renv activation) — this is the default location
install.packages("precommitr")
# verify it landed in the user lib:
.libPaths()[length(.libPaths())]
```

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

1. Edit `inst/templates/pre-commit-config.yaml` and/or `R/hooks.R`.
2. Bump the `Version:` in `DESCRIPTION`.
3. Merge into `main` (or `development`).
4. Tell analysts:

   ```r
   remotes::install_github("QuintenSand/r-package-precommits")
   precommitr::update_config()   # re-copies the YAML
   ```

Because all hooks are `repo: local`, there's nothing to `pre-commit
autoupdate` — the R package upgrade *is* the update.

---

## What's in the shared config

All hooks are dispatched via `precommitr::run_hook("<id>", ...)`:

| Hook id                     | What it does                                          |
| --------------------------- | ----------------------------------------------------- |
| `parsable-R`                | Fails if any `.R` file can't be parsed                |
| `style-files`               | Auto-formats R / Rmd / qmd with **styler** (tidyverse)|
| `lintr`                     | Runs **lintr** (warn-only, never blocks commits)      |
| `no-browser-statement`      | Blocks leftover `browser()` calls (AST-based)         |
| `no-debug-statement`        | Blocks leftover `debug()` / `debugonce()` calls       |
| `no-print-statement`        | (optional) Blocks `print()` outside tests/inst/vignettes |
| `trailing-whitespace`       | Strips trailing whitespace                            |
| `end-of-file-fixer`         | Ensures every file ends with exactly one LF           |
| `mixed-line-ending`         | Normalises line endings to LF                         |
| `check-merge-conflict`      | Catches leftover `<<<<<<<` markers                    |
| `check-yaml`                | Validates YAML files (needs `yaml` package)           |
| `check-added-large-files`   | Blocks accidental commits of files > 2 MB             |

`styler`, `lintr` and `yaml` are listed in `Suggests`, not `Imports` — install
them only if you want the corresponding hooks to do anything.

---

## Function reference

| Function                          | What it does                                       |
| --------------------------------- | -------------------------------------------------- |
| `install_precommit()`             | One-time install of the `pre-commit` binary        |
| `use_precommits()`                | Drop the shared config + activate hooks in a repo  |
| `update_config()`                 | Re-copy the latest shared config into a repo       |
| `check_precommit_install()`       | Is the `pre-commit` executable on PATH?            |
| `run_hook(id, files)`             | (Internal) hook dispatcher invoked by pre-commit   |

---

## FAQ

**Q: Our VM can't reach github.com. Does this still work?**
Yes — that's the whole point. The bundled config uses `repo: local` exclusively
and dispatches every hook through `precommitr`, which is already installed
locally. Once `precommitr` and the `pre-commit` binary are on the VM, the
hooks need zero network access.

**Q: Our internal mirror doesn't have the `styler` / `lintr` / `yaml`
packages. Will `precommitr` still install?**
Yes — those are in `Suggests`, so the package installs without them. The
corresponding hooks will print a friendly "please install X" message and (for
`styler`) fail the commit until installed, or (for `lintr`/`yaml`) skip
silently.

**Q: Can analysts override hooks locally?**
Yes — they can edit the local `.pre-commit-config.yaml`, but the next
`update_config()` will overwrite it. Discourage per-repo drift; raise an
issue on this repo instead so the change gets picked up org-wide.

**Q: What if a hook is too strict on an existing codebase?**
Open a PR on this repo to relax the hook (edit the function in `R/hooks.R`
or the YAML defaults). Don't fork the config per repo.
