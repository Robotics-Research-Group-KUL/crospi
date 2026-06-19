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

**Custom Boost 1.89** is required for `boost::lockfree::spsc_value` triple-buffers. Set `BOOST_189_ROOT` or ensure `$HOME/.local/lib/boost/1.89.0` exists. 

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

### JSON Configuration & Schema Validation

- Every plugin receives a `Json::Value` via `construct()`.
- Access config values with `etasl::JsonChecker` using `/`-delimited paths: `jsonchecker->asDouble(param, "general/sample_time")`
- JSON field names use **kebab-case**: `"topic-name"`, `"varname_prefix"`, `"when_unpublished"`
- Schemas in `crospi_default_plugins/json_schemas/` use discriminator-based validation (`"is-ClassName": { "const": true }`)

### Triple-Buffer Shared Memory (Lock-Free IPC)

`boost::lockfree::spsc_value<T>` connects driver threads to the control loop:
```cpp
typedef boost::lockfree::spsc_value<robotdrivers::DynamicJointDataField> triple_buffer_joint_type;
```

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

## Error Handling

- Custom `etasl::etasl_error` exception with enum error codes
- **CRITICAL**: Always use `fmt::format()` to build error messages — the variadic template constructor was removed:
  ```cpp
  throw etasl_error(etasl_error::JSON_PARSE_ERROR, fmt::format("topic {} not found", name));
  ```
- Fatal errors trigger `rclcpp::shutdown()` + `exit(1)`

## ⚠️ Pitfalls & Gotchas

1. **`DELETEME_*` files** — Many files/classes/folders prefixed with `DELETEME_` or `deleteme`. These are deprecated artifacts. **Do NOT reference, edit, or use them as patterns.**

2. **Two registry systems** — `Registry<Factory>` is deprecated and not used anymore and `SolverRegistry` (for solvers). Don't confuse them.

3. **Multiple joint index maps** — `driver_to_etasl`, `etasl_to_driver`, `jindex`, `name_ndx` all map joints between driver, eTaSL, and ROS domains. Be careful with index transformations.

4. **boost::shared_ptr vs std::shared_ptr** — Solver uses `boost::shared_ptr` because of KDL; everything else uses `std::shared_ptr`. Never mix them.

5. **ROS2 distro checks** — Code uses `ROS_DISTRO` environment variable for conditional compilation. Keep these guards when editing distro-specific code.

6. **No test suite** — The project has only lint checks (ament_lint). There are no unit or integration tests. Test manually after changes.

7. **Commented-out code blocks** — Extensive commented-out code exists (especially in `crospi_node.cpp`). Don't uncomment or follow these patterns.

8. **Several folders are nested submodule** — E.g. `etasl_wrapper`, `crospi_core`, `crospi_default_plugins`, `crospi_interfaces`, are git submodules that contains their own submodules. Initialize with `git submodule update --init --recursive`.

