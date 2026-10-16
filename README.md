# hk-config

Shared [hk](https://hk.jdx.dev) presets for `yoshintame/*` repositories, published as a Pkl package on GitHub releases.

| Module | Contents |
|---|---|
| `base.pkl` | `secrets` (betterleaks, lockfiles excluded), `jactionlint`, `trailing_whitespace`, `newlines`, `merge_conflict`; `commit-msg` checks Conventional Commits |
| `ts.pkl` | `base.pkl` plus `oxfmt`, `oxlint`; `types` (`bun run typecheck`) and `test` (`bun run test`) in the `slow` profile |
| `lib.pkl` | `ts.pkl` plus `package` (`bun run lint:package`) in the `slow` profile, for published packages |
| `builtins.pkl` | hk's builtin steps at the version the presets are built on |

`ts.pkl` and `lib.pkl` target bun projects and call these `package.json` scripts; `lint:package` builds the package itself and checks it, for example with publint and attw.

The top-level `steps` create the `check`, `fix` and `pre-commit` hooks; `pre-commit` fixes and stages. CI runs `hk check --all --slow --no-fail-fast`.

## Usage

`hk.pkl`:

```pkl
amends "package://github.com/yoshintame/hk-config/releases/download/v0.2.0/hk-config@0.2.0#/lib.pkl"

import "package://github.com/yoshintame/hk-config/releases/download/v0.2.0/hk-config@0.2.0#/builtins.pkl"

steps {
  ["oxlint"] {
    exclude = List("**/fixtures/**")
  }
  ["sort_package_json"] = builtins.sort_package_json
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

[env]
_.path = ["node_modules/.bin"]
```

- Override an inherited step by its name, add steps the same way, and turn one off with `skip_steps`, for example `skip_steps = List("test")` in a project without tests.
- `base.pkl` needs `hk`, `betterleaks`, `jactionlint` and `shellcheck`; `ts.pkl` adds `node` and `bun`. `oxfmt` and `oxlint` are `devDependencies`, reached through `node_modules/.bin`.
- Install the git hooks once per clone with `hk install --mise`; linked worktrees share them. Git 2.54+ can instead run `hk install --global --mise` once per machine.

Projects reference hk only through `hk` in `mise.toml`: the hk schema and builtins come from this package. hk 2.x runs presets built on an earlier 2.x schema; a new hk schema arrives as a new `hk-config` release.

## Writing presets

hk evaluates Pkl with its built-in `pklr`, which covers only part of the Pkl standard library:

- import `builtins.pkl` under a module-specific alias (`baseBuiltins`, `tsBuiltins`): a module that amends a preset and imports the builtins under the same name as the preset fails with `Cannot find property … in object of type Dynamic`;
- stdlib collection methods such as `Map.remove` are not available; remove an inherited step with `skip_steps` instead.

Presets never set `skip_steps`: a project assigning its own list would silently replace it.

`scripts/validate-presets.sh` runs `hk validate` on every preset and on `test/consumer.pkl`, the usage example above; `hk check` runs it on any `.pkl` change.

## Release

Push a `vX.Y.Z` tag. The `Release` workflow validates the presets, runs `pkl project package` with the version from the tag and attaches the package metadata and zip to the GitHub release.
