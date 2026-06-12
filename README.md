# zed

Vendored [Zed](https://zed.dev) extensions, pinned, checksummed and
[CodeQL](https://codeql.github.com/)-scanned for supply-chain control.

Upstream extensions listed in [`extensions.json`](./extensions.json) are mirrored into
`extensions/<name>/` by [`.github/workflows/extensions.yaml`](./.github/workflows/extensions.yaml),
each pinned to an exact commit. `extensions.json` doubles as the lock file: you maintain each
entry's `name` and `source` (add a `#<ref>` suffix to `source` to pin a branch, tag or commit),
and the workflow writes back the resolved `commit`, content `checksum` and `version`.

Each extension's tree-sitter grammars are vendored as **git submodules** under
`extensions/<name>/grammars/<grammar>/`, pinned to the grammar's commit. Zed checks grammars out
into exactly that path, so the pinned submodule makes Zed build the grammar from the vendored copy.

## Install

Each `extensions/<name>/` directory is a complete, separately-installable Zed extension.

### Quick: `sync.sh`

```sh
git clone --recurse-submodules https://github.com/chr33s/zed
cd zed && ./sync.sh
```

[`sync.sh`](./sync.sh) pulls the latest commit and grammar submodules, then symlinks every
extension into Zed's installed-extensions directory — which is how Zed registers a *dev
extension*. Re-run it any time to update; it also prunes extensions you've removed. Set
`ZED_EXTENSIONS_DIR` to override the target directory.

LSP extensions work immediately from the committed `extension.wasm`. For grammar extensions,
open Zed → Extensions and **Rebuild** once so Zed compiles the vendored tree-sitter grammars.

### Manual

1. Clone **with submodules** (above), or `git submodule update --init --recursive` if already cloned.
2. In Zed, open the Extensions view (`cmd-shift-x`, or `zed: extensions`).
3. Click **Install Dev Extension** and select a directory under `extensions/`, e.g.
   `extensions/oxc`. Repeat per extension.
