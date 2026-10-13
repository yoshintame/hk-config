# hk-config

Shared [hk](https://hk.jdx.dev) presets for `yoshintame/*` repositories, published as a Pkl package on GitHub releases.

| Preset | Steps |
|---|---|
| `base.pkl` | `secrets` (betterleaks), `jactionlint`, `trailing_whitespace`, `newlines`, `merge_conflict`; `commit-msg` checks Conventional Commits |
| `ts.pkl` | `base.pkl` plus `oxfmt`, `oxlint`; `types` (tsc) and `test` (`bun run test`) in the `slow` profile |

The top-level `steps` create the `check`, `fix` and `pre-commit` hooks; `pre-commit` fixes and stages. CI runs `hk check --all --slow`.

## Usage

`hk.pkl`:

```pkl
amends "package://github.com/yoshintame/hk-config/releases/download/v0.1.0/hk-config@0.1.0#/ts.pkl"

import "package://github.com/jdx/hk/releases/download/v2.6.0/hk@2.6.0#/Builtins.pkl"

steps {
  ["types"] {
    check = "bun run typecheck"
  }
  ["sort_package_json"] = Builtins.sort_package_json
}

skip_steps = List("merge_conflict")
```

- Override an inherited step by its name, add steps the same way, and turn one off with `skip_steps`.
- The tools come from the project's `mise.toml`: `hk`, `betterleaks`, `jactionlint` and `shellcheck` for `base.pkl`; `node` and `bun` for `ts.pkl`. `oxfmt`, `oxlint`, `oxlint-tsgolint` and `typescript` are `devDependencies`, exposed with `[env] _.path = ["node_modules/.bin"]`.
- `hk install` sets up the git hooks.

The preset pins the hk schema version. A new hk release means a new `hk-config` release; projects bump `hk` in `mise.toml` and both URLs in `hk.pkl` together.

## Writing presets

hk evaluates Pkl with its built-in `pklr`, which covers only part of the Pkl standard library:

- import `Builtins.pkl` under a module-specific alias (`baseBuiltins`, `tsBuiltins`): a module that amends a local preset and imports `Builtins` under the same name as the preset fails with `Cannot find property … in object of type Dynamic`;
- stdlib collection methods such as `Map.remove` are not available; remove an inherited step with `skip_steps` instead.

`hk check --all` validates every preset with `HK_FILE=<preset> hk validate`.

## Release

Push a `vX.Y.Z` tag. The `Release` workflow runs `pkl project package` with the version from the tag and attaches the package metadata and zip to the GitHub release.
