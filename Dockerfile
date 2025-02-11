FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# Prevent unnecessary suggestions during installations
RUN echo 'APT::Install-Suggests "0"; APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/00-docker

# Update and install basic tools
# for openocd:
#   libtool pkgconf libusb-1.0-0-dev autotools-dev automake libhidapi-dev 
# for rp2040:
#   gcc-arm-none-eabi
# for yosys:
#   build-essential clang bison flex \
#   libreadline-dev gawk tcl-dev libffi-dev \
#   graphviz xdot pkg-config python3 libboost-system-dev \
#   libboost-python-dev libboost-filesystem-dev zlib1g-dev
# for ICE40 FPGAs:
#   build-essential clang bison flex \
#   libreadline-dev gawk tcl-dev libffi-dev mercurial \
#   graphviz xdot pkg-config python3 libftdi-dev \
#   python3-dev libboost-all-dev cmake libeigen3-dev
# for all FPGAs/openFPGALoader:
#   libftdi1-2 libftdi1-dev libhidapi-libusb0 libhidapi-dev \
#   libudev-dev cmake pkg-config make g++
# for verilog:
#   iverilog verilator
RUN apt-get update && apt-get install -y \
    git make python3 python3-pip \
    libtool pkgconf libusb-1.0-0-dev autotools-dev automake libhidapi-dev \
    gcc-arm-none-eabi \
    build-essential clang bison flex \
    libreadline-dev gawk tcl-dev libffi-dev \
    graphviz xdot libboost-system-dev \
    libboost-python-dev libboost-filesystem-dev zlib1g-dev \
    mercurial \
    libftdi-dev \
    python3-dev libboost-all-dev cmake libeigen3-dev \
    libftdi1-2 libftdi1-dev libhidapi-libusb0 libhidapi-dev \
    libudev-dev g++ \
    iverilog verilator \
    openocd \
    python3-serial

# Install openocd
# ARG OPENOCD_VERSION=v0.12.0
# RUN git clone https://github.com/openocd-org/openocd.git /usr/src/openocd \
#     && cd /usr/src/openocd \
#     && git checkout v0.12.0 \
#     && ./bootstrap \
#     && ./configure --enable-cmsis-dap --enable-cmsis-dap-v2 --enable-stlink --disable-dependency-tracking \
#     && make -j$(nproc) && make install \
#     && cd /

# Install yosys
RUN git clone https://github.com/YosysHQ/yosys.git /usr/src/yosys \
    && cd /usr/src/yosys \
    && git submodule update --init \
    && make -j$(nproc) \
    && make install \
    && cd /

# Install icestorm
RUN git clone https://github.com/YosysHQ/icestorm.git /usr/src/icestorm \
    && cd /usr/src/icestorm \
    && make -j$(nproc) \
    && make install \
    && cd /

# Install nextpnr
RUN git clone --recursive --branch nextpnr-0.7 https://github.com/YosysHQ/nextpnr.git /usr/src/nextpnr \
    && cd /usr/src/nextpnr \
    && mkdir -p build && cd build \
    && cmake .. -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local \
    && make -j$(nproc) \
    && make install \
    && cd /

## Tool for sending FPGA bitstream
RUN apt-get install -y udev \
    && echo 'ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0660", GROUP="plugdev", TAG+="uaccess"' > /etc/udev/rules.d/53-lattice-ftdi.rules

# Install openFPGALoader
RUN git clone https://github.com/trabucayre/openFPGALoader.git /usr/src/openFPGALoader \
    && cd /usr/src/openFPGALoader \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && make install \
    && cd /

# Clone hackster-programmer repo and
# expose the hackster-fpga-program.py script as "hackster-fpga" command
# by creating a symlink to the script in /usr/local/bin
RUN mkdir /hackster && mkdir /mount \
    && git clone https://github.com/kiwih/hackster-programmer.git /hackster/hackster-programmer \
    && chmod +x /hackster/hackster-programmer/hackster-fpga-program.py \
    && ln -s /hackster/hackster-programmer/hackster-fpga-program.py /usr/local/bin/hackster-fpga

WORKDIR /mount

# User should run this with cse-hackster-fw as an attached volume
# this image supports the tools required to build and synthesise programs
