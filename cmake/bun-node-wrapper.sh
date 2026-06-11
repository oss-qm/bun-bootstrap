#!/bin/sh
# Drop-in replacement for the bun executable used by bun's codegen, backed by
# node + tsx. Locate the source tree relative to this script so the tsx loader
# resolves regardless of the caller's working directory (cmake runs codegen
# from the build dir, where there is no node_modules).
HERE="$(cd "$(dirname "$0")/.." && pwd)"
export NODE_PATH="$HERE/node_modules"

# Start Node 26.3 and register tsx for TypeScript execution. The tsx specifier
# must be an absolute path: `--import` resolves bare specifiers against the cwd.
exec /home/nekrad/src/oc-workspace/_WORK_/opencode/target/bin/node \
    --import "$HERE/node_modules/tsx/dist/loader.mjs" "$@"
