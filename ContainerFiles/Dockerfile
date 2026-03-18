# syntax=docker/dockerfile:1.4
FROM osrf/ros:humble-desktop-full

# Set environment to avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install System Dependencies, Lua, Python, and Tools in one block
# Added cleaning of apt lists to reduce size
RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3-pip vim tree python3-venv \
    lua5.1 liblua5.1.0-dev luarocks cmake build-essential \
    ros-dev-tools openssh-client tmux wget ros-$ROS_DISTRO-plotjuggler-ros\
    && luarocks install dkjson \
    && luarocks install jsonschema \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup User
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG CROSPI_WORKSPACE=/home/$USERNAME/ros2_crospi_ws

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# 3. Install Python packages
# Combined pip installs + cleaned cache
RUN pip3 install --no-cache-dir --upgrade \
    setuptools==58.2.0 \
    jsonref jsonschema colorama flask flask-cors requests pandas numpy matplotlib

# 4. Build and Install Boost (Heavy Operation)
# Chained commands prevent the source code and build artifacts from committing to the layer
WORKDIR /tmp
RUN wget -O boost_1_89_0.tar.gz "https://sourceforge.net/projects/boost/files/boost/1.89.0/boost_1_89_0.tar.gz/download" \
    && tar -xzf boost_1_89_0.tar.gz \
    && cd boost_1_89_0 \
    && mkdir -p /home/$USERNAME/.local/lib/boost/1.89.0 \
    && ./bootstrap.sh --prefix=/home/$USERNAME/.local/lib/boost/1.89.0 \
    && ./b2 -j$(nproc) install \
    && cd /tmp \
    && rm -rf boost_1_89_0 boost_1_89_0.tar.gz \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/.local

# 5. Prepare Workspace Directory & SSH
# We setup directories and permissions BEFORE cloning to avoid 'chown -R' layer duplication
RUN mkdir -p -m 0700 /home/$USERNAME/.ssh \
    && ssh-keyscan gitlab.kuleuven.be >> /home/$USERNAME/.ssh/known_hosts \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh \
    && mkdir -p $CROSPI_WORKSPACE/src \
    && chown -R $USERNAME:$USERNAME $CROSPI_WORKSPACE

# 6. Switch to User for Cloning
# Cloning as the user prevents permission issues without needing 'chown' later
USER $USERNAME
WORKDIR $CROSPI_WORKSPACE

# 7. Clone Repositories
# Utilizing cache mount for SSH is good
RUN git clone --recursive https://github.com/Robotics-Research-Group-KUL/crospi.git src/crospi \
    && git clone --recursive https://github.com/Robotics-Research-Group-KUL/betfsm.git src/betfsm

# 8. Install Dependencies
# Switch briefly to root to install system dependencies via rosdep
USER root

RUN apt-get update --fix-missing
RUN apt-get update && rosdep install --from-paths src -y --ignore-src \
    && rm -rf /var/lib/apt/lists/* 
    # && touch src/etasl_ros2_default_plugins/CMakeLists.txt

# 9. Build Workspace
USER $USERNAME
RUN . /opt/ros/humble/setup.sh && \
    colcon build --symlink-install --packages-skip crospi_default_plugins
    # colcon build --symlink-install --packages-skip etasl_ros2_default_plugins

# 10. Final Setup
RUN echo "source $CROSPI_WORKSPACE/install/setup.bash" >> /home/$USERNAME/.bashrc

ARG WORKSPACE
