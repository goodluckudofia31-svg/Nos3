#!/bin/bash -i
# ---------------------------------------------------------------------------
# NOS3 Railway container entrypoint.
#
# Runs the simulation + flight software + ground station headlessly and
# keeps the container alive so Railway's health check / port binding has
# something to attach to.
# ---------------------------------------------------------------------------
set -e
cd /opt/nos3

echo "=== Starting NOS3 simulation stack ==="

# Flight software (cFS) — background
echo "--- Launching flight software ---"
./scripts/fsw/launch_sat.sh &
FSW_PID=$!

# Sit briefly so FSW sockets exist before GSW tries to attach
sleep 5

# Ground software / COSMOS operator interface — foreground, on $PORT
# Railway injects $PORT; default to COSMOS's usual 2900 for local docker runs.
export PORT="${PORT:-2900}"
echo "--- Launching ground software on port ${PORT} ---"
./scripts/gsw/launch_gsw.sh &
GSW_PID=$!

# Forward termination signals so `docker stop` / Railway restarts are clean
trap "echo 'Stopping NOS3...'; ./scripts/stop.sh; kill -TERM $FSW_PID $GSW_PID 2>/dev/null" SIGTERM SIGINT

wait -n $FSW_PID $GSW_PID
echo "A NOS3 process exited — shutting down the rest."
./scripts/stop.sh
