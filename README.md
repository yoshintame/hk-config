# hk-config

Shared [hk](https://hk.jdx.dev) presets for `yoshintame/*` repositories, published as a Pkl package on GitHub releases.

| Module | Contents |
|---|---|
| `presets/base.pkl` | `secrets` (betterleaks, lockfiles excluded), `jactionlint`, `trailing_whitespace`, `newlines`, `merge_conflict`; `commit-msg` checks Conventional Commits |
| `presets/ts.pkl` | `base.pkl` plus `oxfmt`, `oxlint`; `types` (`bun run typecheck`) and `test` (`bun run test`) in the `slow` profile |
| `presets/ts-lib.pkl` | `ts.pkl` plus `package` (`bun run lint:package`) in the `slow` profile, for published packages |
| `presets/svelte.pkl` | `ts.pkl` with `**/*.svelte` added to the `oxfmt` glob, plus `build` (`bun run build`) in the `slow` profile, for SvelteKit projects |
| `presets/nix.pkl` | `base.pkl` plus `treefmt` (the flake's formatter); `flake` (`nix flake check`) in the `slow` profile |
| `presets/python.pkl` | `base.pkl` plus `ruff`, `ruff_format`; `types` (`uv run --frozen pyright`) and `test` (`uv run --frozen pytest -q`) in the `slow` profile |
| `builtins.pkl` | hk's builtin steps at the version the presets are built on |

`ts.pkl`, `ts-lib.pkl` and `svelte.pkl` target bun projects and call these `package.json` scripts; `lint:package` builds the package itself and checks it, for example with publint and attw.

The top-level `steps` create the `check`, `fix` and `pre-commit` hooks; `pre-commit` fixes and stages. CI runs `hk check --all --slow --no-fail-fast`.

## Usage

`hk.pkl` (the same file is validated in CI as `test/consumer.pkl`):

```pkl
amends "package://github.com/yoshintame/hk-config/releases/download/v0.4.0/hk-config@0.4.0#/presets/ts-lib.pkl"

import "package://github.com/yoshintame/hk-config/releases/download/v0.4.0/hk-config@0.4.0#/builtins.pkl"

steps {
  ["oxlint"] {
    exclude = List("**/fixtures/**")
  }
  ["shellcheck"] = builtins.shellcheck
}

skip_steps = List("merge_conflict")
```

`mise.toml`:

```toml
[tools]
betterleaks = "1.9.0"
bun = "1.4.3"
hk = "2.6.0"
jactionlint = "2.1.0"
node = "24.21.0"
shellcheck = "0.11.0"
```

- Override an inherited step by its name, add steps the same way, and turn one off with `skip_steps`, for example `skip_steps = List("test")` in a project without tests.
- `base.pkl` needs `hk`, `betterleaks`, `jactionlint` and `shellcheck`; `ts.pkl` adds `node` and `bun`. `oxfmt` and `oxlint` are `devDependencies`: `ts.pkl` puts `node_modules/.bin` in front of `PATH` for the `oxfmt` and `oxlint` steps only, so hk itself, its `git` calls, the other steps and CI jobs never resolve commands from `node_modules`, where any dependency may ship a bin named `git` or `betterleaks`.
- `svelte.pkl` targets SvelteKit projects. hk's builtin `oxfmt` step leaves `*.svelte` out of its glob, so the preset adds it; oxfmt formats `.svelte` files only with its `svelte` option on and the `svelte` package installed: without `oxfmt({ svelte: true })` from `@yoshintame/ox-config` it silently matches no `.svelte` file, so they go unchecked. The builtin `oxlint` glob already covers `.svelte`. `types` runs `bun run typecheck`, which in a SvelteKit project is `svelte-check`. `build` runs `bun run build`, so CI fails on a broken build or prerender that the type check does not see; it depends on `types`, because both regenerate `.svelte-kit` through `svelte-kit sync` and race when run in parallel.
- `python.pkl` targets uv projects with `ruff`, `pyright` and `pytest` in the dev dependency group: it puts `.venv/bin` in front of `PATH` for the `ruff` and `ruff_format` steps only, for the same reason as `ts.pkl`, so run `uv sync` before `hk check`. It needs `uv` and `python` in `mise.toml` besides the `base.pkl` tools.
- `nix.pkl` targets flakes whose `formatter` is a treefmt wrapper, as treefmt-nix provides. treefmt has no read-only mode, so the check builds `.#formatter.<system>` once and compares every file with `treefmt --stdin`; the fix runs `nix fmt`. It needs `nix` on `PATH`; a flake that needs `--impure` overrides the `flake` step's `check`.
- Install the git hooks once per clone with `hk install --mise`; linked worktrees share them. Git 2.54+ can instead run `hk install --global --mise` once per machine.

Projects reference hk only through `hk` in `mise.toml`: the hk schema and builtins come from this package. hk 2.x runs presets built on an earlier 2.x schema; a new hk schema arrives as a new `hk-config` release.

## Layout

`pkl/` is the Pkl project root and holds only what ships: `PklProject`, `builtins.pkl` and `presets/`. Everything else configures this repository: `hk.pkl` checks it with `presets/base.pkl`, `test/consumer.pkl` is the usage example above, `test/svelte-consumer.pkl`, `test/python-consumer.pkl` and `test/nix-consumer.pkl` the same for `svelte.pkl`, `python.pkl` and `nix.pkl`.

## Writing presets

hk evaluates Pkl with its built-in `pklr`, which covers only part of the Pkl standard library:

- import `builtins.pkl` under a module-specific alias (`baseBuiltins`, `tsBuiltins`): a module that amends a preset and imports the builtins under the same name as the preset fails with `Cannot find property … in object of type Dynamic`;
- stdlib collection methods such as `Map.remove` are not available; remove an inherited step with `skip_steps` instead.

Presets never set `skip_steps`: a project assigning its own list would silently replace it.

`scripts/validate-presets.sh` runs `hk validate` on every preset and on `test/consumer.pkl`; `hk check` runs it on any `.pkl` change.

## Release

Every push to `main` runs the shared `release-semantic.yml` from `yoshintame/workflows` after the checks. semantic-release takes the version from Conventional Commits, `@semantic-release/exec` runs `pkl project package pkl`, and the package metadata and zip are attached to the GitHub release. `package.json` exists only for this: the release tools stay pinned by `bun.lock`.
