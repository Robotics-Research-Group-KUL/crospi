#
# Some custom aliases and bash functions for working and developing with crospi
#
# These are completely optional and not required to work with crospi, but you
# could find them useful
# 
# 2026, E. Aertbeliën
#
###########################################  Added for distrobox crospi ######################

# application configuration file for crospi:
export CROSPI_CONFIG='$[crospi_application_template]/applications/application_example_tutorials/application_example_tutorials.setup.json'



# turn of annoying notifications for colcon builds:
alias alert=
export COLCON_EXTENSION_BLOCKLIST=colcon_core.event_handler.desktop_notification

# turn on autocomplete for colcon:
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash


# ── Workspace root finder (used by everything else) ──────────
_find_ws_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    [[ -d "$dir/src"  ]] && { echo "$dir"; return; }
    dir="$(dirname "$dir")"
  done
  echo ""
}

# ── Navigation ───────────────────────────────────────────────
cws()      { local r="$(_find_ws_root)"; [[ -n "$r" ]] && cd "$r" || echo "No workspace found"; }


# ── Build ────────────────────────────────────────────────────
build_ws() { (cws && colcon build --symlink-install) }

load_ws() {
  local ws; ws="$(_find_ws_root)"
  local f="$ws/install/setup.${SHELL##*/}"
  [[ -f "$f" ]] && source "$f" && echo "Sourced $f" || echo "No setup file found"
}

# ── Misc ─────────────────────────────────────────────────────
ros2env() {
  echo "ROS_DISTRO         = ${ROS_DISTRO:-<unset>}"
  echo "ROS_DOMAIN_ID      = ${ROS_DOMAIN_ID:-0 (default)}"
  echo "RMW_IMPLEMENTATION = ${RMW_IMPLEMENTATION:-<default>}"
  echo "AMENT_PREFIX_PATH (first 3):"
  echo "$AMENT_PREFIX_PATH" | tr ':' '\n' | head -3 | sed 's/^/  /'
}

wstatus() {
  echo "Workspace : $(_find_ws_root)"
  echo "ROS distro: ${ROS_DISTRO:-<not sourced>}"
  echo "Overlays  : $(echo "$AMENT_PREFIX_PATH" | tr ':' '\n' | wc -l) paths"
  echo "$(echo "$AMENT_PREFIX_PATH" | tr ':' '\n' )"
}

ros2list() {
  echo "1) topics  2) nodes  3) services  4) actions"
  read -rp "Pick: " n
  case $n in
    1) ros2 topic list ;;
    2) ros2 node list ;;
    3) ros2 service list ;;
    4) ros2 action list ;;
  esac
}

roscd() {
  local pkg="$1"
  local ws; ws="$(_find_ws_root)"
  [[ -z "$ws" ]] && { echo "No workspace found"; return 1; }

  # find all matching package.xml files
  local -a matches
  mapfile -t matches < <(find "$ws/src" -iname "package.xml" | grep -i "$pkg" | sort)

  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "No package matching '$pkg' found"
    return 1
  elif [[ ${#matches[@]} -eq 1 ]]; then
    cd "$(dirname "${matches[0]}")"
  else
    echo "Multiple matches:"
    for i in "${!matches[@]}"; do
      echo "  $((i+1))) ${matches[$i]}"
    done
    read -rp "Pick [1-${#matches[@]}]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#matches[@]} )); then
      cd "$(dirname "${matches[$((choice-1))]}")"
    else
      echo "Invalid choice"
      return 1
    fi
  fi
}

# ── Help ─────────────────────────────────────────────────────
crospi_help() {
	cat << EOF
Aliases and bash functions
--------------------------

Autocomplete ros2 is turned on

roscd            : cd into a ros package
cws              : cd into current workspace root
find_ws          : function to get workspace base if you are somewhere in the directory 
                   tree of a workspace (the 'current' workspace)
load_ws          : reload current work space ("install" has be be present in base)
build_ws         : build current workspace
run_crospi_node  : run crospi with the configuration specified in CROSPI_CONFIG env variable
ros2list         : list topics/nodes/services/actions
ros2env          : display main ros2 env. variables
wstatus          : workspace status

Common repositories
-------------------

git clone --recursive git@github.com:Robotics-Research-Group-KUL/crospi.git
git clone git@github.com:Robotics-Research-Group-KUL/betfsm.git
git clone --recursive https://github.com/Robotics-Research-Group-KUL/crospi_application_template.git
git clone https://github.com/UniversalRobots/Universal_Robots_ROS2_Description.git

git clone --recursive https://github.com:Robotics-Research-Group-KUL/crospi.git
git clone https://github.com/Robotics-Research-Group-KUL/betfsm.git
git clone --recursive git@github.com:Robotics-Research-Group-KUL/crospi_application_template.git
git clone https://github.com/UniversalRobots/Universal_Robots_ROS2_Description.git

Building
--------
colcon build --symlink-install
source install/setup.bash

RVIZ
------
ros2 launch crospi_application_template application_example_tutorials.launch.py

Crospi node:
-------------
ros2 run crospi_core crospi_node --ros-args -p config_file:='\$[crospi_application_template]/applications/application_example_tutorials/application_example_tutorials.setup.json' -p simulation:=true

BeTFSM:
--------------

python3 skill_example.py


EOF
}

run_crospi_node() {
    echo "Running crospi with config $CROSPI_CONFIG"
    cat << EOF
ros2 run crospi_core crospi_node --ros-args -p config_file:="$CROSPI_CONFIG" -p simulation:=true
EOF
    ros2 run crospi_core crospi_node --ros-args -p config_file:="$CROSPI_CONFIG" -p simulation:=true
}

# Remove host-bled ~/.local/bin entries (distrobox home sharing artefact) 
# otherwise problem with uv new installed python interpreters.
PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^/home/[^/]*/.local/bin" | tr '\n' ':')

source /opt/ros/$ROS_DISTRO/setup.bash

