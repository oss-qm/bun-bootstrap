cmake_minimum_required(VERSION 3.24)
message(STATUS "Configuring Bun")

list(APPEND CMAKE_MODULE_PATH
  ${CMAKE_SOURCE_DIR}/cmake
  ${CMAKE_SOURCE_DIR}/cmake/targets
  ${CMAKE_SOURCE_DIR}/cmake/tools
  ${CMAKE_SOURCE_DIR}/cmake/analysis
  ${CMAKE_SOURCE_DIR}/cmake/scripts
)

include(Policies)
include(Globals)

if (CMAKE_HOST_WIN32)
  # Workaround for TLS certificate verification issue on Windows when downloading from GitHub
  # Remove this once we've bumped the CI machines build image
  set(CMAKE_TLS_VERIFY 0)
endif()

# --- Compilers ---

if(CMAKE_HOST_APPLE)
  include(SetupMacSDK)
endif()
include(SetupLLVM)

# --- Project ---

parse_package_json(VERSION_VARIABLE DEFAULT_VERSION)
optionx(VERSION STRING "The version of Bun" DEFAULT ${DEFAULT_VERSION})
project(Bun VERSION ${VERSION})

# Bun uses C++23, which is compatible with BoringSSL's C++17 requirement
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(Options)
include(CompilerFlags)

# --- Tools ---

include(SetupGit)
include(SetupBuildkite)
include(SetupBun)
include(SetupNpm)
include(SetupEsbuild)
include(SetupZig)
include(SetupRust)

find_program(SCCACHE_PROGRAM sccache)
if(SCCACHE_PROGRAM AND NOT DEFINED ENV{NO_SCCACHE})
  include(SetupSccache)
else()
  find_program(CCACHE_PROGRAM ccache)
  if(CCACHE_PROGRAM)
    include(SetupCcache)
  endif()
endif()

# Generate dependency versions header
include(GenerateDependencyVersions)

# --- Install codegen runtime dependencies ---

# BuildBun runs codegen at *configure* time (e.g. the bindgenv2 list-outputs
# step), which needs node_modules (notably tsx) to already exist. The build-time
# register_npm_install() edges only run during `cmake --build`, which is too
# late. Bun normally installs deps via scripts/build.mjs before cmake; this
# bootstrap drives cmake directly, so install them here. Skipped when tsx is
# already present, so rebuilds don't pay for a redundant install.
if(NOT EXISTS ${CMAKE_SOURCE_DIR}/node_modules/tsx/dist/loader.mjs)
  message(STATUS "Installing root npm dependencies (tsx, esbuild, ...)")
  execute_process(
    COMMAND ${NPM_EXECUTABLE} install --ignore-scripts
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMAND_ERROR_IS_FATAL ANY
  )
endif()

# --- Generate source lists ---

# Bun normally runs scripts/glob-sources.mjs (via scripts/build.mjs) to populate
# cmake/sources/*.txt from cmake/Sources.json. Those files are gitignored and
# regenerated on every build. This bootstrap drives cmake directly (without
# build.mjs), so generate them here, before BuildBun reads them via
# absolute_sources(). Without this the lists are empty and dependency tracking
# breaks (e.g. node-fallbacks/*.js never gets built before the zig step).
execute_process(
  COMMAND ${NODE_EXECUTABLE} ${CMAKE_SOURCE_DIR}/scripts/glob-sources.mjs
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  COMMAND_ERROR_IS_FATAL ANY
)

# --- Targets ---

include(BuildBun)

# --- Analysis ---

if(ENABLE_ANALYSIS)
  include(RunClangFormat)
  include(RunClangTidy)
  include(RunZigFormat)
  include(RunPrettier)
endif()
