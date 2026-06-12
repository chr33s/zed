#!/usr/bin/env bash
# Install/update this repo's Zed extensions as local dev extensions.
#
# Pulls the latest commit and vendored grammar submodules, then symlinks each
# extensions/<name>/ into Zed's installed-extensions directory. Zed treats a
# symlinked extension as a "dev extension", so this is the headless equivalent
# of "Install Dev Extension". Safe to re-run any time to update.
#
# Override the target directory with ZED_EXTENSIONS_DIR.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Sync this repo and its grammar submodules from GitHub.
if [ -d "$root/.git" ]; then
  git -C "$root" pull --ff-only
  git -C "$root" submodule update --init --recursive
fi

# 2. Locate Zed's extensions directory.
if [ -n "${ZED_EXTENSIONS_DIR:-}" ]; then
  ext_dir="$ZED_EXTENSIONS_DIR"
else
  case "$(uname -s)" in
    Darwin) ext_dir="$HOME/Library/Application Support/Zed/extensions" ;;
    Linux)  ext_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zed/extensions" ;;
    *) echo "Unsupported OS $(uname -s); set ZED_EXTENSIONS_DIR" >&2; exit 1 ;;
  esac
fi
installed="$ext_dir/installed"
mkdir -p "$installed"

# 3. Symlink each extension into installed/<id> (a symlink marks it as dev).
desired=$'\n'
for manifest in "$root"/extensions/*/extension.toml; do
  [ -e "$manifest" ] || continue
  src="$(dirname "$manifest")"
  id="$(sed -n 's/^[[:space:]]*id[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -1)"
  [ -n "$id" ] || { echo "skip ${src#"$root"/} (no id in extension.toml)" >&2; continue; }
  link="$installed/$id"
  if [ -L "$link" ]; then
    [ "$(readlink "$link")" = "$src" ] || { rm -f "$link"; ln -s "$src" "$link"; }
  elif [ -e "$link" ]; then
    echo "skip $id: $link exists and is not a symlink (installed from the registry?)" >&2
    continue
  else
    ln -s "$src" "$link"
  fi
  echo "linked $id -> ${src#"$root"/}"
  desired="$desired$id"$'\n'
done

# 4. Remove dev-extension symlinks that point into this repo but are gone now.
for link in "$installed"/*; do
  [ -L "$link" ] || continue
  case "$(readlink "$link")" in
    "$root"/extensions/*)
      id="$(basename "$link")"
      case "$desired" in
        *$'\n'"$id"$'\n'*) : ;;
        *) rm -f "$link"; echo "removed $id (no longer in repo)" ;;
      esac
      ;;
  esac
done

echo
echo "Done. Zed reloads installed extensions automatically (or restart it)."
echo "LSP extensions use the committed extension.wasm directly. For grammar"
echo "extensions, open Zed → Extensions and Rebuild once to compile the"
echo "vendored tree-sitter grammars."
