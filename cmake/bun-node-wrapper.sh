#!/bin/sh
# Drop-in replacement for the bun executable used by bun's codegen, backed by
# node + tsx. Locate the source tree relative to this script so the tsx loader
# resolves regardless of the caller's working directory (cmake runs codegen
# from the build dir, where there is no node_modules).
HERE="$(cd "$(dirname "$0")/.." && pwd)"
export NODE_PATH="$HERE/node_modules"

# node: prefer $BUN_BOOTSTRAP_NODE (the build points it at the freshly built
# node in the install prefix); otherwise fall back to `node` on $PATH. Register
# tsx for TypeScript execution -- the specifier must be an absolute path, since
# `--import` resolves bare specifiers against the cwd.
NODE="${BUN_BOOTSTRAP_NODE:-node}"
exec "$NODE" --import "$HERE/node_modules/tsx/dist/loader.mjs" "$@"
