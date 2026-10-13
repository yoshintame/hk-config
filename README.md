# hk-config

Shared [hk](https://hk.jdx.dev) presets for `yoshintame/*` repositories, published as a Pkl package on GitHub releases.

| Module | Contents |
|---|---|
| `base.pkl` | `secrets` (betterleaks, lockfiles excluded), `jactionlint`, `trailing_whitespace`, `newlines`, `merge_conflict`; `commit-msg` checks Conventional Commits |
| `ts.pkl` | `base.pkl` plus `oxfmt`, `oxlint`; `types` (`bun run typecheck`) and `test` (`bun run test`) in the `slow` profile |
| `builtins.pkl` | hk's builtin steps at the version the presets are built on |

The top-level `steps` create the `check`, `fix` and `pre-commit` hooks; `pre-commit` fixes and stages. CI runs `hk check --all --slow`.

## Usage

`hk.pkl`:

```pkl
amends "package://github.com/yoshintame/hk-config/releases/download/v0.1.0/hk-config@0.1.0#/ts.pkl"

import "package://github.com/yoshintame/hk-config/releases/download/v0.1.0/hk-config@0.1.0#/builtins.pkl"

steps {
  ["oxlint"] {
    exclude = List("**/generated/**")
  }
  ["sort_package_json"] = builtins.sort_package_json
}

skip_steps = List("merge_conflict")
```

- Override an inherited step by its name, add steps the same way, and turn one off with `skip_steps`.
- `ts.pkl` expects `typecheck` and `test` scripts in `package.json`; a project without tests drops the step with `skip_steps = List("test")`.
- The tools come from the project's `mise.toml`: `hk`, `betterleaks`, `jactionlint` and `shellcheck` for `base.pkl`; `node` and `bun` for `ts.pkl`. `oxfmt` and `oxlint` are `devDependencies`, exposed with `[env] _.path = ["node_modules/.bin"]`.
- `hk install` sets up the git hooks.

Projects reference hk only through `hk` in `mise.toml`: the hk schema and builtins come from this package. A newer hk binary runs the presets of an older schema; a new hk schema arrives as a new `hk-config` release.

## Writing presets

hk evaluates Pkl with its built-in `pklr`, which covers only part of the Pkl standard library:

- import `builtins.pkl` under a module-specific alias (`baseBuiltins`, `tsBuiltins`): a module that amends a preset and imports the builtins under the same name as the preset fails with `Cannot find property … in object of type Dynamic`;
- stdlib collection methods such as `Map.remove` are not available; remove an inherited step with `skip_steps` instead.

`scripts/validate-presets.sh` runs `hk validate` on every preset and on `test/consumer.pkl`, the usage example above; `hk check` runs it on any `.pkl` change.

## Release

Push a `vX.Y.Z` tag. The `Release` workflow validates the presets, runs `pkl project package` with the version from the tag and attaches the package metadata and zip to the GitHub release.
