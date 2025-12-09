FROM osrf/ros:humble-desktop-full

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y git python3-pip vim tree python3-venv\
    lua5.1 liblua5.1.0-dev luarocks cmake build-essential ros-dev-tools software-properties-common\
    lsb-release

RUN luarocks install dkjson
RUN luarocks install jsonschema


# Create a non-root user to avoid file permission issues
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN pip3 install setuptools==58.2.0 \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN pip3 install jsonref jsonschema colorama flask flask-cors requests


# -----------------------------
# Boost 1.89
# -----------------------------
ENV BOOST_VERSION=1.89.0
ENV BOOST_DIR=/opt/boost/${BOOST_VERSION}

# Set working directory
WORKDIR /tmp

# Download and extract Boost 1.89.0
RUN wget -O boost_1_89_0.tar.gz "https://sourceforge.net/projects/boost/files/boost/1.89.0/boost_1_89_0.tar.gz/download" && \
    tar -xvzf boost_1_89_0.tar.gz && \
    rm boost_1_89_0.tar.gz

# Build and install Boost
WORKDIR /tmp/boost_1_89_0

# RUN mkdir -p /opt/boost/1.89.0 && \
#     ./bootstrap.sh --prefix=/opt/boost/1.89.0 && \
#     ./b2 -j$(nproc) install

RUN mkdir -p /home/$USERNAME/.local/lib/boost/1.89.0 && \
    ./bootstrap.sh --prefix=/home/$USERNAME/.local/lib/boost/1.89.0 && \
    ./b2 -j$(nproc) install

# Clean up build files to reduce image size
WORKDIR /
RUN rm -rf /tmp/boost_1_89_0


RUN rosdep init || true && \
    rosdep update

# -----------------------------
# Environment variables
# -----------------------------
ENV CMAKE_PREFIX_PATH=${BOOST_DIR}:${CMAKE_PREFIX_PATH}
ENV LD_LIBRARY_PATH=${BOOST_DIR}/lib:${LD_LIBRARY_PATH}
ENV BOOST_ROOT=${BOOST_DIR}



# Create a workspace
RUN mkdir -p /ros2_ws/src
WORKDIR /ros2_ws

ARG WORKSPACE
