# Crospi — AI Agent Instructions

## Project Overview

Crospi is a **ROS2 constraint-based reactive robot control framework** using the eTaSL (expression graph Task Specification Language). It orchestrates robot behaviors via lifecycle-managed nodes, a plugin system for input/output handling and robot drivers, and Lua-based task specifications.

- **Official docs**: https://rob.pages.gitlab.kuleuven.be/crospi/
- **License**: LGPL-3.0-only
- **Target ROS2 distros**: From humble onwards.
- **Language**: C++17 with ament_cmake; Lua 5.1 for task specs; Python 3 for utilities

## Repository Structure (Git Meta-Repo)

This is a **meta-repository** with 5 git submodules. Before making changes, identify which submodule the file belongs to:

| Submodule | Purpose |
|---|---|
| `crospi_core/` | Core lifecycle node, plugin interfaces, utilities, Python support, Lua scripts |
| `crospi_default_plugins/` | Concrete InputHandler, OutputHandler, and RobotSimulator plugins (loaded via pluginlib) |
| `crospi_interfaces/` | ROS2 custom `.msg`, `.srv`, `.action` definitions |
| `etasl_wrapper/` | Build wrapper compiling eTaSL C++ libraries in-tree from GitLab sources |
| `robot_drivers_crospi/template_driver_crospi/` | Template RobotDriver plugin example |

See each submodule's `README.md` for package-specific details.

## Changelog

Every change must be recorded in `CHANGELOG.md` at the meta-repo root:
- Add entries to the `[Unreleased]` section at the top (create it if missing), describing the changes with respect to the last commit of this meta-repo.
- Group entries by submodule (`crospi_core`, `crospi_default_plugins`, ..., `Meta-repo`) and then by `Added` / `Changed` / `Removed` / `Fixed`. Reference submodule commit hashes where available, and flag uncommitted changes.
- Explicitly mark **behaviour changes** and breaking changes to configuration files, topics, services or plugin base-class headers.
- On commit, rename `[Unreleased]` to the date (and meta-repo commit hash/version) and start a new `[Unreleased]` section for the next changes.

## Build System

```bash
# Source the ROS2 underlay + workspace overlay
source /opt/ros/humble/setup.bash
source /opt/ros2_crospi_ws/install/setup.bash

# Build (from workspace root)
cd /opt/ros2_crospi_ws
colcon build --symlink-install
```

**Build order**: `etasl_wrapper` → `crospi_interfaces` → `crospi_core` → `crospi_default_plugins` (colcon handles this automatically).

**Boost**: only the system Boost of the distro is needed (rosdep key `boost`). The Boost 1.89 `spsc_value` triple buffer is vendored in `crospi_core/include/crospi_boost/` (see Triple-Buffer section); no Boost 1.89 installation, `BOOST_189_ROOT` or `/opt/boost_*` is needed anymore.

**Containers & CI**: one `containers/Containerfile` (`--build-arg ROS_DISTRO=<distro>`, works with podman and docker, no user baked in) published as `ghcr.io/robotics-research-group-kul/crospi-betfsm:ros2-<distro>` by `.github/workflows/container-images.yml`; `.github/workflows/build-and-test.yml` builds the packages in the official `ros:<distro>-ros-base` images. Both use one matrix over the supported distros (humble, jazzy, kilted, lyrical, rolling): add a distro there, not new files. Build dependencies must come from `package.xml` (rosdep), not from the Containerfile. The user documentation of the containers is in the GitLab docs repo (`documentation/docs/markdown/installation/docker.md`).

**Custom bash helpers** See `custom_aliases_crospi.sh` for convenience bash functions.

## Architecture & Key Patterns

### Lifecycle 

Every component follows a lifecycle state machine, which the orchestrator is free to call. An example:

```
construct() → initialize() → on_configure() → on_activate()
                                                   ↓
                                             [update() loop]
                                                   ↓
                    on_deactivate() → on_cleanup() → finalize()
```

### Plugin System (pluginlib)

Three plugin families, all base classes in `crospi_core`:
- **InputHandler** — subscribes to ROS2 topics, writes to eTaSL input channels
- **OutputHandler** — reads eTaSL output expressions, publishes to ROS2 topics
- **RobotDriver** / **RobotSimulator** — interfaces with real or simulated robots via triple-buffer shared memory

Plugin registration requires two things:
1. An entry in `crospi_default_plugins/plugins.xml`
2. `PLUGINLIB_EXPORT_CLASS(ClassName, BaseClass)` at the bottom of the `.cpp`

### CMake of crospi_core and plugin packages

- `crospi_core` finds all dependencies of its libraries once, in the top-level `CMakeLists.txt` (`crospi_core_exported_dependencies`), and exports them with `ament_export_dependencies`. The same list must be in `crospi_core/package.xml` as `<depend>` (transitive for rosdep/bloom). Add a new library dependency to both.
- Plugin packages only need:
  ```cmake
  find_package(ament_cmake REQUIRED)
  find_package(crospi_core REQUIRED)   # brings rclcpp, etasl, Eigen3, pluginlib, tf2, jsoncpp, fmt, ...
  target_link_libraries(my_plugin PUBLIC crospi_core::crospi_core)
  pluginlib_export_plugin_description_file(crospi_core plugins.xml)
  ```
  and `<depend>crospi_core</depend>` in `package.xml`. Only libraries beyond what `crospi_core` provides (e.g. MuJoCo, `hardware_interface`) are found/declared explicitly.
- `crospi_core::crospi_core` is an INTERFACE umbrella over `crospi_utils`, `crospi_node_utils` and `robot_interfacing_utils` (still usable individually).
- Use `target_link_libraries(... PUBLIC <targets>)` with namespaced targets and `${<msg_pkg>_TARGETS}` on all distros (available since Humble). Do not use `ament_target_dependencies` or `ROS_DISTRO` branches in CMake.
- `ament_export_dependencies` / `ament_export_libraries` only work in the top-level `CMakeLists.txt`: calls in an `add_subdirectory()` scope are silently lost.

### JSON Configuration & Schema Validation

- Every plugin receives a `Json::Value` via `construct()`.
- Access config values with `etasl::JsonChecker` using `/`-delimited paths: `jsonchecker->asDouble(param, "general/sample_time")`
- JSON field names use **kebab-case**: `"topic-name"`, `"varname_prefix"`, `"when_unpublished"`
- Schemas in `crospi_default_plugins/json_schemas/` use discriminator-based validation (`"is-ClassName": { "const": true }`)
- The blackboard (`crospi_utils/blackboard.cpp`) implements only a subset of JSON schema: `type` (object/string/number/integer/boolean/array), `properties` (+ `default` filling), `required`, `additionalProperties`, `oneOf`, `allOf` (applied sequentially, each schema on the output of the previous one), `enum`, `const`, `minimum`/`maximum`, `minItems`/`maxItems`, `$ref`. It ignores `dependencies`, `if`/`then`: fields declared only inside those are neither validated nor default-filled. Keywords next to `oneOf`/`allOf`/`$ref` (except `default`, read by the parent) are ignored. Data files without a `"$schema"` member are not validated at all.
- The schema bundler (jsonref) drops keys next to a `$ref`; to attach e.g. a `default` to a reference, use `{"default": ..., "allOf": [{"$ref": ...}]}`.
- Driver thread scheduling: `thread_scheduling` (`{"policy": "SCHED_OTHER" | "SCHED_FIFO" | "SCHED_RR", "priority": int}`) in a robotdriver/robotsimulator entry overrides the global `/robot/thread_scheduling` (default `SCHED_OTHER`, i.e. scheduling untouched). RT priorities are limited to 1–98 (`t_manager::MAX_RT_PRIORITY`). The schema is defined once in the application template (`schemas/thread_scheduling.json`) and applied to every robotdriver and robotsimulator via `allOf` in `schemas/robot.json`; driver/simulator schemas must not redefine it.

### Triple-Buffer Shared Memory (Lock-Free IPC)

`crospi_boost::lockfree::spsc_value<T>` connects driver threads to the control loop:
```cpp
#include <crospi_boost/lockfree/spsc_value.hpp>
typedef crospi_boost::lockfree::spsc_value<robotdrivers::DynamicJointDataField> triple_buffer_joint_type;
```
- `crospi_boost` is Boost 1.89's `boost/lockfree/spsc_value.hpp` plus the headers it needs (~590 files, header-only, BSL-1.0), renamed (`boost/` → `crospi_boost/`, `boost::` → `crospi_boost::`, `BOOST_*` → `CROSPI_BOOST_*`, `mpl_` → `crospi_mpl_`) so it can coexist with the system Boost (1.74/1.83/...) in the same translation unit.
- Use `crospi_boost::` only for the lockfree triple buffers; all other Boost usage (`boost::shared_ptr`, `boost::chrono`, KDL/eTaSL) is the system Boost.

### eTaSL Integration

- eTaSL libraries are built in-tree via `add_subdirectory()` in `etasl_wrapper/CMakeLists.txt`
- Task specifications are written in Lua and loaded at runtime
- `LUA_PATH`/`LUA_CPATH` are auto-configured via environment hooks
- Robot specs are passed to Lua via stringified JSON (`_JSON_ROBOTSPECIFICATION_STRING_`)

## Naming Conventions

| Category | Convention | Example |
|---|---|---|
| Classes | PascalCase | `JointStateInputHandler` |
| Methods/functions | snake_case | `on_activate()`, `update_controller_output()` |
| Files | snake_case `.cpp`/`.hpp` | `joint_state_input_handler.cpp` |
| Private members | trailing `_` | `node_`, `parameters_` |
| SharedPtr typedef | `typedef std::shared_ptr<T> SharedPtr` | In every class header |
| Namespace | `etasl` | For all Crospi code |
| Nested namespace | `robotdrivers` | For shared-memory data structures |

## Node Name & Multiple Instances

- The node name defaults to `crospi_node` (`etasl::DEFAULT_NODE_NAME` in `crospi_node_utils/node_naming.hpp`) and can be changed with `--ros-args -r __node:=<node_name>`, e.g. to run several crospi nodes simultaneously.
- With a non-default name, output topics are published as `/<node_name>/<topic>` via `etasl::node_scoped_topic()`: the `topic-name` of every output handler (rewritten centrally in `IOHandlerManager::construct_output_handlers`, so output handler plugins must use the `topic-name` field) and the event topic. Input handler and robot driver topics are not changed. With the default name, all topics are unchanged.
- Services are node-relative (`~/readTaskSpecificationFile`, ...), i.e. `/crospi_node/...` by default and `/<node_name>/...` otherwise.

## Error Handling

- Custom `etasl::etasl_error` exception with enum error codes
- **CRITICAL**: Always use `fmt::format()` to build error messages — the variadic template constructor was removed:
  ```cpp
  throw etasl_error(etasl_error::JSON_PARSE_ERROR, fmt::format("topic {} not found", name));
  ```
- Fatal errors trigger `rclcpp::shutdown()` + `exit(1)`

## Logging

- Never use `std::cout`/`std::cerr` for diagnostics in ROS-linked code; use ROS 2 logging and match the style already used in the file:
  - `crospi_node.cpp`: `RCUTILS_LOG_{INFO,WARN,ERROR}_NAMED(get_name(), ...)`
  - Managers/plugins holding a node pointer: `RCLCPP_*(node_->get_logger(), ...)`
  - Utility classes without a node (e.g. `BlackBoard`): `RCLCPP_*(rclcpp::get_logger("<component>"), ...)`
- Levels: `INFO` for one-off lifecycle/user-relevant events, `DEBUG` for verbose dumps (JSON configs, internal state), `WARN`/`ERROR` for problems.
- Do not add logging inside per-cycle code (`update()`, driver thread loops): it breaks real-time timing.
- Exceptions where plain prints are intentional: `robot_interfacing_utils` (`thread_manager.cpp` does not link rclcpp), `PrintObserver` (printing is its purpose), and user-facing Lua `print()` in `scripts/lib`.
- Do not leave debug prints or commented-out code behind when finishing a change.

## ⚠️ Pitfalls & Gotchas

1. **`DELETEME_*` files** — Files/folders prefixed with `DELETEME_` or `deleteme` are deprecated artifacts (removed from `crospi_core`, but still present e.g. in `crospi_default_plugins` and `ContainerFiles_deteleme`). **Do NOT reference, edit, or use them as patterns.**

2. **Two registry systems** — `Registry<Factory>` is deprecated and not used anymore and `SolverRegistry` (for solvers). Don't confuse them.

3. **Multiple joint index maps** — `driver_to_etasl`, `etasl_to_driver`, `jindex`, `name_ndx` all map joints between driver, eTaSL, and ROS domains. Be careful with index transformations.

4. **boost::shared_ptr vs std::shared_ptr** — Solver uses `boost::shared_ptr` because of KDL; everything else uses `std::shared_ptr`. Never mix them.

5. **ROS2 distro checks** — Code uses `ROS_DISTRO` environment variable for conditional compilation. Keep these guards when editing distro-specific C++ code. (CMake no longer branches on `ROS_DISTRO`, see the CMake section.)

6. **No test suite** — The project has only lint checks (ament_lint). There are no unit or integration tests. Test manually after changes.

7. **Commented-out code blocks** — `crospi_core` has been cleaned of dead commented-out code; don't reintroduce it. Other submodules may still contain some: don't uncomment or follow these patterns.

8. **Legacy test nodes are not built** — `crospi_core/src/ros2_nodes/*` other than `crospi_node` (e.g. `shared_memory_test*`, `simple_etasl_node`, `erwin_node`) are disabled in `CMakeLists.txt` and kept only for reference. They may no longer compile (e.g. `simple_etasl_node` includes a removed `IO_handlers_deleteme.hpp`). Don't use them as patterns.

9. **Robot simulators live in `crospi_default_plugins`** — e.g. `simple_kinematic_simulation` (`src/simulators/`). There is no simulator implementation in `crospi_core`, only the `RobotSimulator`/`RobotDriver` base classes.

10. **Plugin base-class headers are public API** — `crospi_core/include/robot_interfacing_utils/robotdriver.hpp`, `include/crospi_utils/inputhandler.hpp` and `outputhandler.hpp` are implemented by external plugins (`crospi_default_plugins`, `robot_drivers_crospi/*`). After changing them, rebuild those packages too: `colcon build --packages-up-to crospi_default_plugins template_driver_crospi`.

11. **Vendored Boost is generated, never edit it by hand** — `crospi_core/include/crospi_boost/` is produced by `crospi_core/tools/vendor_boost/vendor_boost.py <boost_include_dir> crospi_core/include` (source version in `crospi_boost/VENDORED_FROM.txt`). To update it, rerun the script with a newer Boost and rebuild all packages. Never include `<boost/lockfree/spsc_value.hpp>` or add `find_package(Boost 1.89 ...)` again.

12. **Several folders are nested submodule** — E.g. `etasl_wrapper`, `crospi_core`, `crospi_default_plugins`, `crospi_interfaces`, are git submodules that contains their own submodules. Initialize with `git submodule update --init --recursive`.

