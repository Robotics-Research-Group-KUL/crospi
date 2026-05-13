###########################################  Added for distrobox crospi ######################

# application configuration file for crospi:
export CROSPI_CONFIG='$[crospi_application_template]/applications/application_example_tutorials/application_example_tutorials.setup.json'



# turn of notifications for colcon builds:
alias alert=
export COLCON_EXTENSION_BLOCKLIST=colcon_core.event_handler.desktop_notification

# turn on autocomplete for colcon:
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash

# find the work space base in whose subtree I currently am located.
find_ws() {
    local curr_dir=$PWD
    while [ "$curr_dir" != "/" ]; do
        if [ -d "$curr_dir/src" ] && [ -d "$curr_dir/install" ]; then echo "$curr_dir"; return 0; fi
        curr_dir=$(dirname "$curr_dir")
    done
    return 1
}

# load the work space install/setup.bash in whose subtree I currently am located.
load_ws() {
    local ws=$(find_ws)
    if [ -z "$ws" ]; then
        echo "Error: No workspace with an /install directory found in parent tree."
        ws=$ROS2_DEFAULT_WORKSPACE 
    fi
    source /opt/ros/humble/setup.bash
    source "$ws/install/setup.bash"
    echo "Sourced workspace: $ws"
}

# build the work space  in whose subtree I currently am located.
build_ws() {
    local ws=$(find_ws)
    if [ -z "$ws" ]; then echo "No workspace found: used $ROS2_DEFAULT_WORKSPACE"; ws=$ROS2_DEFAULT_WORKSPACE; fi
    (cd "$ws" && colcon build --symlink-install "$@")
}



#
# roscd
#
# from https://github.com/Martin-Oehler/ros2cd/blob/main/roscd.sh
#
#

# Auto completion
function _roscd_autocomplete() {
    # Clear previously generated completions
    COMPREPLY=()

    local cur="${COMP_WORDS[COMP_CWORD]}"
    local packages
    packages=$(ros2 pkg list 2>/dev/null)

    COMPREPLY=($(compgen -W "${packages}" -- "$cur"))
    return 0
}

# Register the completion function for the roscd command.
complete -F _roscd_autocomplete roscd

function roscd() {
    # Check for help arguments
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Usage: roscd [<pkg_name>]"
        echo "  If <pkg_name> is given, cd into the directory containing the package installation."
        echo "  If no argument is given, tries to cd into COLCON_PREFIX_PATH/../src if it exists,"
        echo "  otherwise into COLCON_PREFIX_PATH if it exists."
        return 0
    fi

    # If no argument is given, go to the default workspace's root
    if [ -z "$1" ]; then
    	echo "no package given"
    	return 1
    fi

    local pkg_name="$1"

    # If AMENT_PREFIX_PATH is not set or empty, we cannot proceed with package search.
    if [ -z "$AMENT_PREFIX_PATH" ]; then
        echo "ERROR: AMENT_PREFIX_PATH is not set. Make sure you have sourced your ROS2 workspace."
        return 1
    fi

    # Split AMENT_PREFIX_PATH by ':'
    echo "$AMENT_PREFIX_PATH" | IFS=':' read -r -a paths 

    for prefix in "${paths[@]}"; do
        # Check if prefix/share/ament_index/resource_index/packages/<pkg_name> exists
        local index_dir="$prefix/share/ament_index/resource_index/packages"
        if [ -f "$index_dir/$pkg_name" ]; then
            # We found the package in this prefix
            local pkg_dir="$prefix/share/$pkg_name"
            local pkg_xml="$pkg_dir/package.xml"

            if [ -L "$pkg_xml" ]; then
                # package.xml is a symlink, follow it
                local real_pkg_xml
                real_pkg_xml=$(readlink -f "$pkg_xml")
                local real_pkg_dir
                real_pkg_dir=$(dirname "$real_pkg_xml")
                cd "$real_pkg_dir" || return 1
            else
                # package.xml is not a symlink, just cd into pkg_dir
                cd "$pkg_dir" || return 1
            fi
            return 0
        fi
    done

    echo "Package '$pkg_name' not found."
    return 1
}

#
# end of roscd
#



crospi_help() {
	cat << EOF
Aliases and bash functions
--------------------------

Autocomplete ros2 is turned on

roscd            : cd into a ros package
find_ws          : function to get workspace base if you are somewhere in the directory 
                   tree of a workspace (the 'current' workspace)
load_ws          : reload current work space ("install" has be be present in base)
build_ws         : build current workspace
run_crospi_node  : run crospi with the configuration specified in CROSPI_CONFIG env variable

Common repositories
-------------------
git clone --recursive https://github.com/Robotics-Research-Group-KUL/crospi_application_template.git
git clone https://github.com/UniversalRobots/Universal_Robots_ROS2_Description.git
git clone --recursive -b devel/restructuring git@github.com:Robotics-Research-Group-KUL/betfsm.git

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

Orchestration:
--------------
cd src/crospi_application_template/skill_specifications/libraries/skill_lib_example/skill_specifications/
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


