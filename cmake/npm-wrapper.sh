#!/bin/sh
# npm shim for the bun bootstrap build. cmake's register_npm_install() calls
# this for `bun install`/`npm install` steps; we redirect to the npm shipped
# with the freshly built node in the install prefix, pinning our node 26 rather
# than relying on whatever `node` the npm-cli shebang resolves via $PATH.
#
# The file is named "npm*" on purpose: register_npm_install() keys off the
# executable basename matching ^npm to pass `--ignore-scripts` instead of bun's
# `--frozen-lockfile`.
NODE=/home/nekrad/src/oc-workspace/_WORK_/opencode/target/bin/node
NPM_CLI=/home/nekrad/src/oc-workspace/_WORK_/opencode/target/lib/node_modules/npm/bin/npm-cli.js
exec "$NODE" "$NPM_CLI" "$@"
