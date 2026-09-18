# nos3-railway

Deployment repository for running [NASA NOS3](https://github.com/nasa/nos3) (Operational Simulator for Space Systems) on [Railway](https://railway.app), instead of NOS3's default local Vagrant/Docker dev workflow.

This repo is intentionally small — Railway only needs to see this, not the full NOS3 source. NOS3 and the 42 dynamics simulator are cloned fresh **during the Railway build**, so nothing gets downloaded to your own machine.

## Why this exists

Railway's automatic builder (Railpack) looks for familiar entry points — `package.json`, `requirements.txt`, `Dockerfile` — at the root of a repo. NOS3's actual entry point is a `Makefile` that drives a multi-target build (flight software, dynamics sim, ground software) meant to run interactively inside a Vagrant VM or a manually-run Docker container with host volumes mounted in. Railpack can't infer any of that, so pointing Railway straight at `nasa/nos3` fails.

This repo gives Railway an explicit `Dockerfile` instead, so it knows exactly what to build.

```
Railway
   │
   ▼
Dockerfile
   │
   ▼
ivvitc/nos3-64 (NASA's own build/dev image)
   │
   ├── clone nasa/nos3
   ├── clone nasa-itc/42
   ├── build 42
   └── make config / fsw / sim / gsw
   │
   ▼
start.sh → cFS + ground station, ground station web UI on $PORT
   │
   ▼
Browser
```

## What's real vs. what needs your testing

I built this from NOS3's actual `Makefile`, `scripts/`, and `scripts/env.sh` (that's where `ivvitc/nos3-64` and the 42 clone command in the `Dockerfile` come from), plus NASA IV&V's own [deployment repo](https://github.com/nasa-itc/deployment) which publishes that base image and confirms the intended container-based build flow.

What I could **not** do from here: actually run a Docker build. Compiling cFS + 42 + the ground software is a heavy, multi-gigabyte, long-running process that needs a real Docker daemon — something I don't have access to in the environment that wrote this. So:

- The `Dockerfile`'s dependency/base-image layer is grounded in NOS3's own tooling and should be solid.
- The build steps (`make config`, `make fsw`, `make sim`, `make gsw`) are the real commands NOS3 uses, but running them unattended inside a Docker build (rather than interactively in a dev VM, which is how NOS3 is normally built) is not an officially documented path. **Expect to iterate on build errors** the first few times you deploy — check the Railway build log against the corresponding script under `scripts/` in NOS3 for whichever step fails.
- `start.sh` launches flight software and ground software and keeps the container alive; the exact ground-station web port (COSMOS defaults to `2900`) may need adjusting once you can see it actually run.

## Deploying

1. Push this repo to GitHub (or connect it directly).
2. In Railway: **New Project → Deploy from GitHub repo** → select this repo.
3. Railway will read `railway.toml` and build from the `Dockerfile` instead of guessing.
4. Once deployed, open the Railway-assigned domain — that's your ground station web UI.

## If you want a cleaner split later

Right now this is one container running both the spacecraft simulation (42 + cFS) and the ground station together — the simplest thing that could plausibly work. A more robust setup, worth doing once this base version boots successfully, is two Railway services in the same project:

```
Railway Project
├── spacecraft-sim   (42 + cFS)
└── ground-station   (COSMOS/YAMCS)  → browser
```

That isolates the ground station's uptime from the simulation process, and makes it possible to scale or restart either independently. Happy to build that split out once the single-container version is confirmed running.

## License

NOS3 is licensed under NASA's Open Source Agreement (NOSA 1.3). This deployment repo only adds build/deployment glue around the upstream project; none of NOS3's own source is duplicated here — it's cloned from `nasa/nos3` at build time.
