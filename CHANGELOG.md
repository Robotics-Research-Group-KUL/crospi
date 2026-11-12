# Changelog

All notable changes to the Crospi meta-repository and its submodules are recorded here,
newest first. Each entry lists the changes relative to the previous commit of this
meta-repository, grouped by submodule.

## [Unreleased] — 2026-11-12

Changes with respect to meta-repo commit `4d02361` ("Improved readme file", 2026-07-16).

### `crospi_core` (submodule `9965e1c` → `63e3be4`, plus uncommitted changes)

#### Added
- **Vendored Boost 1.89 `spsc_value` — Boost 1.89 is no longer required** (uncommitted).
  - `include/crospi_boost/`: `boost/lockfree/spsc_value.hpp` and the 592 Boost 1.89 headers it
    needs (header-only, BSL-1.0, `LICENSE_1_0.txt` included), renamed `boost/` → `crospi_boost/`,
    `boost::` → `crospi_boost::`, `BOOST_*` → `CROSPI_BOOST_*`, `mpl_` → `crospi_mpl_` so they
    cannot clash with the system Boost included in the same translation unit (eTaSL/KDL).
  - `tools/vendor_boost/vendor_boost.py` regenerates the tree from any Boost installation.
  - Verified: compiles together with system Boost 1.83 in both include orders (C++17/20),
    `crospi_core`, `crospi_default_plugins` and `template_driver_crospi` build with no Boost 1.89
    in the environment, and `crospi_node` runs the tutorial application (configure/activate/
    deactivate) with log output identical to the Boost 1.89 build.
- **Configurable node name / multiple crospi nodes** (`3a39a5b`).
  - The node name can be changed with `--ros-args -r __node:=<node_name>`; the default
    stays `crospi_node` (`etasl::DEFAULT_NODE_NAME`, new header
    `include/crospi_node_utils/node_naming.hpp`).
  - New helper `etasl::node_scoped_topic()`: with a non-default name, output topics are
    published as `/<node_name>/<topic>`. Applied centrally to the `topic-name` of every
    output handler in `IOHandlerManager::construct_output_handlers` and to the event topic.
    Input handler and robot driver topics are unchanged. With the default name, nothing
    changes (backward compatible).
  - Services are now node-relative (`~/etasl_console`, `~/readTaskSpecificationFile`,
    `~/readRobotSpecification`, `~/readTaskSpecificationString`, `~/readTaskParameters`),
    i.e. `/crospi_node/...` by default and `/<node_name>/...` otherwise.
- **Configurable driver thread scheduling** (`85bd791`, `5b5cd2d`).
  - New `thread_scheduling` setting (`{"policy": "SCHED_OTHER" | "SCHED_FIFO" | "SCHED_RR",
    "priority": int}`), set globally in `/robot/thread_scheduling` or per robotdriver /
    robotsimulator entry (the per-driver value takes precedence).
  - New `t_manager::parse_scheduling()` and `t_manager::MAX_RT_PRIORITY` (= 98) in
    `thread_manager.hpp/.cpp`; real-time priorities must be in [1, 98], the priority is
    ignored for `SCHED_OTHER`.
  - `RobotDriverManagerLockFree::create_thread_str()` now takes the global default
    scheduling as an argument.
- **Blackboard JSON-schema support** (`85bd791`, `5b5cd2d`): `integer` type (with `const`,
  `minimum`/`maximum`), `allOf` (sub-schemas applied sequentially on the result of the
  previous one) and `enum`. Shared `minimum`/`maximum` check factored into
  `checkNumericRange()`.

- **Dependencies are exported / inherited** (uncommitted). `find_package(crospi_core)` now finds all
  dependencies of the crospi_core libraries (rclcpp, rclcpp_lifecycle, rclcpp_action, pluginlib, etasl, Eigen3,
  jsoncpp, fmt, tf2, tf2_ros, tf2_geometry_msgs, crospi_interfaces, message packages, ...). Previously the
  `ament_export_dependencies` calls were in `add_subdirectory()` scopes and silently lost, so every plugin had
  to repeat all `find_package` calls.
- New umbrella target `crospi_core::crospi_core` (INTERFACE: `crospi_utils`, `crospi_node_utils`,
  `robot_interfacing_utils`); plugins only need `find_package(crospi_core)` and
  `target_link_libraries(<plugin> PUBLIC crospi_core::crospi_core)` (uncommitted).

#### Changed
- **Breaking (plugin base-class header):** `robotdriver.hpp` now uses
  `crospi_boost::lockfree::spsc_value` (include `<crospi_boost/lockfree/spsc_value.hpp>`). Driver
  plugins that use the `triple_buffer_*_type` typedefs keep compiling, but must be rebuilt, and
  must drop `find_package(Boost 1.89 ...)` from their `CMakeLists.txt` (uncommitted).
- CMake: removed the Boost 1.89 resolution (`BOOST_189_ROOT`, `$HOME/.local/lib/boost/1.89.0`,
  `Boost_NO_SYSTEM_PATHS`) and `${Boost_INCLUDE_DIRS}` from all targets; `package.xml` declares
  `<depend>boost</depend>` (system Boost, used for `boost/chrono.hpp`) (uncommitted).
- CMake simplified (uncommitted): dependencies found once in the top-level `CMakeLists.txt`; all targets use
  `target_link_libraries(... PUBLIC ...)` with namespaced targets / `${pkg_TARGETS}`; the
  `ament_target_dependencies` / `ROS_DISTRO` branches and the per-subdirectory `find_package`,
  `ament_export_libraries` and `ament_export_dependencies` calls were removed. `fmt` is linked as `fmt::fmt`.
  Verified on Kilted only; Humble provides the same targets but is not yet built.
- `package.xml` now declares all exported dependencies (`rclcpp`, `pluginlib`, `tf2*`, `eigen`,
  `libjsoncpp-dev`, `fmt`, ...), so they are transitive for rosdep and for the Debian packages (uncommitted).
- **Behaviour change:** driver threads are no longer hard-coded to `SCHED_FIFO` with
  priority 90. Without a `thread_scheduling` setting they now run under the default Linux
  scheduler (`SCHED_OTHER`). Setups relying on real-time scheduling must add
  `thread_scheduling` to their configuration.
- Diagnostics moved from prints to ROS 2 logging; verbose dumps moved to `DEBUG` (`5ec7070`).

- `package.xml`: the non-existent rosdep keys `python-jsonref-pip` / `python-jsonschema-pip` (they made
  `rosdep install` fail) replaced by `python3-jsonschema` (apt) and a comment that jsonref (no rosdep rule,
  not packaged by Ubuntu) is installed with `pip3 install jsonref` (uncommitted).

#### Removed (`5ec7070`)
- All `DELETEME_*` / `*_deleteme*` sources and headers (old factories, `task`,
  `loghandler`, `printobserver`, `robot`, `IO_handlers_deleteme`, old robot driver managers,
  `feedback_struct_deleteme`, etc.), the `include/crospi_utils/old/` folder and the
  `scripts/schema_DELETEME/` schemas.
- The unused `simple_kinematic_simulation` copy in `crospi_core` (the plugin lives in
  `crospi_default_plugins/src/simulators/`).
- Dead commented-out code throughout (notably `crospi_node.cpp`, the drivers manager and
  the shared-memory structures). In total ~10.9k lines removed across 146 files.

#### Restored
- `include/crospi_utils/etasl_error.hpp`: commented-out old constructors and the removed
  variadic-`fmt` constructor note put back (`63e3be4`).

#### Fixed
- **Build on ROS 2 Rolling** (uncommitted): ament_index_cpp 1.14.1 removed `get_package_share_directory.hpp`
  and the string returning `get_package_prefix()`. New header `include/crospi_utils/ament_index.hpp` with
  `etasl::get_package_share_directory()` / `etasl::get_package_prefix()`, which use the std::filesystem API where
  available (Jazzy and later) and the string API on Humble; used in `string_interpolate.cpp` (unused include
  removed from `crospi_node.cpp`). Plugins can use it as well.
- **Build on ROS 2 Humble** (uncommitted): `etasl::node_scoped_topic()` used
  `LifecycleNode::get_fully_qualified_name()`, which does not exist in Humble; the name is now built from
  `get_namespace()` and `get_name()` (same result, verified for root and nested namespaces).
- Binaries no longer load two Boost.Chrono libraries (1.89 from `/opt/boost_1.89.0` and the
  system 1.83 through eTaSL) in the same process; only the system Boost is linked now.

### Meta-repo
- `AGENTS.md`: documented the blackboard's supported JSON-schema subset, the jsonref
  `$ref`/`default` workaround, driver thread scheduling, node naming / multiple instances,
  logging conventions, and new pitfalls (legacy test nodes not built, simulators live in
  `crospi_default_plugins`, plugin base-class headers are public API). Added the changelog
  rule (this file).
- Added `CHANGELOG.md`.

- **One user Containerfile and one image workflow** (uncommitted): the six
  `.podman/user_containers/<distro>/Containerfile` were merged into `containers/Containerfile`
  (`--build-arg ROS_DISTRO=<distro>`) and the six `podman-push-ros2-<distro>.yml` workflows into one matrix
  workflow, `.github/workflows/container-images.yml` (Humble, Jazzy, Kilted, Lyrical, Rolling; the end-of-life
  Iron image is no longer built).
- **Image renamed** (uncommitted): `crospi-betfsm-podman` → `crospi-betfsm`
  (`ghcr.io/robotics-research-group-kul/crospi-betfsm:ros2-<distro>`), since the images work with Podman and
  Docker. The old name is still pushed during a transition period (remove `LEGACY_IMAGE` from
  `container-images.yml` after the first release). README: new "Using the containers" section.
  - The Containerfile no longer builds Boost 1.89, and no longer installs build dependencies by hand
    (rosdep installs them from the package.xml files); distribution differences are detected instead of
    duplicated: PCRE from source only where `libpcre3-dev` is missing (Ubuntu 26.04), PlotJuggler only where
    released, python packages from apt on Ubuntu >= 26.04 and from pip before, `PIP_BREAK_SYSTEM_PACKAGES`
    only at build time.
  - **Behaviour change:** pull requests only build the images; they are pushed only from `main` and
    releases (before, every pull request overwrote the published images).
- `README.md`: per-distro build badges kept (same workflow file names), plus a badge for `container-images.yml`
  (uncommitted).
- GitHub Actions updated to their Node.js 24 versions (Node.js 20 is deprecated on the runners)
  (uncommitted): `actions/checkout` v4 → v7 (all workflows), `actions/upload-pages-artifact` v3 → v5 and
  `actions/deploy-pages` v4 → v5 (API documentation). `upload-pages-artifact` no longer includes dotfiles in the
  artifact by default, which the API documentation site does not need.
- **The images contain the tested commit** (uncommitted): new build argument `CROSPI_REF` (branch, tag or full
  commit hash, default `main`); `container-images.yml` passes the commit that triggered the workflow (the head of
  a pull request), so pull requests test their own code instead of `main`.
- **Fixed** (uncommitted): on Ubuntu 26.04 (Lyrical, Rolling) the PCRE source build was never used, because
  `apt-cache show libpcre3-dev` succeeds for a package that is only referenced by others; now checks for an
  installation candidate (`apt-cache policy`).
- **Fixed** (uncommitted): image pushes are retried (3 attempts) since GHCR occasionally answers an upload with a
  transient `500 Internal Server Error`.
- **Fixed:** the user container builds failed in `rosdep install` because `crospi_core` and
  `crospi_default_plugins` declared the non-existent rosdep keys `python-jsonref-pip` and
  `python-jsonschema-pip` (see their entries).
- **CI uses standard images** (uncommitted): the build steps of the six `build-and-test-ros2-<distro>.yml`
  workflows were moved into one reusable workflow, `.github/workflows/build-and-test-reusable.yml`, that builds
  `etasl_wrapper`, `crospi_interfaces`, `crospi_core`, `crospi_default_plugins` and (new) `template_driver_crospi`
  in the official `ros:<distro>-ros-base` image; all build dependencies come from rosdep. The
  `build-and-test-ros2-<distro>.yml` workflows (Humble, Jazzy, Kilted, Lyrical, Rolling) are now ~30-line callers
  (triggers + distribution only), kept as separate workflows so that every distribution has its own README badge.
  The end-of-life Iron is no longer built.
- Removed: the custom build images `.docker/build_test/*/Dockerfile` and the six
  `docker-push-ros2-<distro>.yml` workflows that built and pushed them weekly
  (`ghcr.io/robotics-research-group-kul/crospi-build-test`), only needed for Boost 1.89.
- `AGENTS.md`: new section on the CMake of crospi_core and plugin packages.
- `AGENTS.md`: Boost/triple-buffer sections updated for `crospi_boost`; new pitfall on
  regenerating (never hand-editing) the vendored headers.

### `crospi_default_plugins` (uncommitted)
- `package.xml`: the non-existent rosdep keys `python-jsonref-pip` / `python-jsonschema-pip` replaced by
  `python3-jsonschema` (apt) and a comment that jsonref is installed with `pip3 install jsonref`.
- `CMakeLists.txt`: removed the Boost 1.89 resolution and `${Boost_INCLUDE_DIRS}`.
- `CMakeLists.txt` reduced to `find_package(crospi_core)` + `crospi_core::crospi_core` (no repeated
  `find_package` calls, no `ROS_DISTRO` branch); `package.xml` only depends on `crospi_core` (plus the python
  pip keys).

### `robot_drivers_crospi/template_driver_crospi` (uncommitted)
- `CMakeLists.txt`: removed `find_package(Boost 1.89 CONFIG REQUIRED)` and `${Boost_INCLUDE_DIRS}`.
- `CMakeLists.txt` reduced to `find_package(crospi_core)` + `crospi_core::crospi_core`; the long
  commented-out "external library" example was replaced by a one-line hint; `package.xml` only depends on
  `crospi_core`.

### Other submodules
- `crospi_interfaces`, `etasl_wrapper`: no changes.
