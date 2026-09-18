# ---------------------------------------------------------------------------
# NOS3 (NASA Operational Simulator for Space Systems) — Railway deployment
#
# This builds NOS3 for headless/cloud operation instead of the interactive
# local Vagrant/Docker dev workflow NOS3 ships with by default.
#
# Base image: ivvitc/nos3-64, the official pre-built build/dev environment
# published by NASA's IV&V team (github.com/nasa-itc/deployment). It already
# has every compiler, library and Python package NOS3's build needs, so we
# don't hand-roll apt-get lists that would drift out of sync with upstream.
#
# NOS3 and the 42 dynamics simulator are cloned fresh during THIS build —
# nothing is downloaded to your machine.
# ---------------------------------------------------------------------------
FROM ivvitc/nos3-64:latest

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# ---------------------------------------------------------------------------
# 1. Fetch source
# ---------------------------------------------------------------------------
WORKDIR /opt
RUN git clone --recurse-submodules --depth 1 https://github.com/nasa/nos3.git

# 42 is normally cloned by `make prep` into ~/.nos3/42 on a dev machine.
# We put it in the same relative layout so NOS3's scripts find it.
RUN mkdir -p /root/.nos3 \
    && git clone --depth 1 -b dev_20260403 https://github.com/nasa-itc/42.git /root/.nos3/42

# ---------------------------------------------------------------------------
# 2. Build 42
# ---------------------------------------------------------------------------
WORKDIR /root/.nos3/42
RUN make

# ---------------------------------------------------------------------------
# 3. Configure and build NOS3 (flight software, simulators, ground software)
#
# NOTE: this is the heaviest, least-tested part of this Dockerfile. NOS3's
# own build is normally driven interactively via `make all` on a dev
# workstation/VM with a full desktop; running it unattended in a Docker
# build layer is not an officially documented path. If a step here fails,
# check the exact error against fsw/nos3_defs and gsw build logs — this
# Dockerfile gets you correctly positioned to debug it, not a guaranteed
# green build.
# ---------------------------------------------------------------------------
WORKDIR /opt/nos3
RUN make config
RUN make fsw
RUN make sim
RUN make gsw

# ---------------------------------------------------------------------------
# 4. Runtime
# ---------------------------------------------------------------------------
# OpenC3 COSMOS (NOS3's default ground station) serves its web UI on 2900.
EXPOSE 2900

COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

WORKDIR /opt/nos3
CMD ["/opt/start.sh"]
