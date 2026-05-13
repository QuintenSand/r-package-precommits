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

```mermaid
flowchart TB
    subgraph S1["1. One-time setup (per machine)"]
        direction LR
        A1["install.packages('remotes')<br/>remotes::install_github(<br/>&nbsp;&nbsp;'QuintenSand/r-package-precommits')"] --> A2["pre-commit binary on PATH<br/>(pipx / pip / conda / brew)"]
    end

    subgraph S2["2. Per repo (once)"]
        direction LR
        B1["precommitr::use_precommits()"] --> B2[".pre-commit-config.yaml<br/>copied into repo root"]
        B2 --> B3["pre-commit install<br/>writes .git/hooks/pre-commit"]
    end

    subgraph S3["3. Every git commit"]
        direction TB
        C1["git commit"] --> C2[".git/hooks/pre-commit<br/>reads the YAML"]
        C2 --> C3["for each hook id:<br/>Rscript -e<br/>'precommitr::run_hook(id, commandArgs(TRUE))'<br/>(respects .Rprofile / renv)"]
        C3 --> C4["dispatcher sources<br/>inst/hooks/&lt;id&gt;.R"]
        C4 --> C5{"script<br/>exit code"}
        C5 -- "0 (pass)" --> C6["commit proceeds ✅"]
        C5 -- "1 (fail / auto-fix)" --> C7["commit blocked ❌<br/>re-stage, commit again"]
    end

    S1 --> S2 --> S3
```

The single source of truth is the YAML in `inst/templates/` **plus** the
scripts in `inst/hooks/<id>.R`. To roll out a change org-wide, edit one of
those, bump the package version, ask the team to upgrade.

### Org-wide update lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Maintainer
    participant Repo as precommitr repo
    actor Analyst
    participant Hook as pre-commit on commit

    Maintainer->>Repo: Edit inst/hooks/&lt;id&gt;.R or YAML
    Maintainer->>Repo: Bump Version in DESCRIPTION
    Maintainer->>Repo: git push
    Analyst->>Repo: remotes::install_github(...)
    Analyst->>Analyst: precommitr::update_config()
    Note over Analyst: latest YAML now in the repo
    Analyst->>Hook: git commit
    Hook->>Hook: runs updated inst/hooks/&lt;id&gt;.R
```

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

Hooks are invoked with plain `Rscript`, so the project's `.Rprofile` runs
normally — which means `renv` auto-activates when present. The hook then uses
whichever library `.libPaths()` resolves to.

**If your project uses `renv`** (the common pattern on analyst VMs), install
`precommitr` into the project library and snapshot it:

```r
renv::install("QuintenSand/r-package-precommits")
renv::snapshot()
```

That puts `precommitr` in `renv/library/` and records it in `renv.lock`, so
the hook will find it. Repeat this in each repo, or use
`renv::settings$external.libraries()` to share one install across projects.

**If your project doesn't use `renv`**, install `precommitr` to your user
library and the hook will pick it up:

```r
remotes::install_github("QuintenSand/r-package-precommits")
.libPaths()[length(.libPaths())]   # where it landed
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

1. Edit `inst/templates/pre-commit-config.yaml` and/or the relevant script
   under `inst/hooks/<id>.R`.
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
Open a PR on this repo to relax the hook (edit the script in
`inst/hooks/<id>.R` or the YAML defaults). Don't fork the config per repo.
