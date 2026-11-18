# base-devel

Multi-toolchain development container image based on `debian:trixie-slim`, bundling:

- **Node.js** (`node`, `npm`, `npx`)
- **uv + Python** (`uv`, `uvx`, `python`, `python3`)
- **Bun** (`bun`, `bunx`)
- **Rust + Cargo** (`rustc`, `cargo`, `rustup`)
- **Go** (`go`, `gofmt`)
- Common system build tools (`build-essential`, `git`, `pkg-config`, `libssl-dev`, `curl`, `ca-certificates`, `sudo`, etc.)

## Build Locally (Apple `container`)

```bash
container build -t base-devel:trixie .
```

### Customizing Versions or User UID/GID

All toolchain versions and user settings are configurable via `--build-arg`:

```bash
container build -t base-devel:trixie \
  --build-arg NODE_VERSION=26 \
  --build-arg PYTHON_VERSION=3.15 \
  --build-arg GO_VERSION=1.27 \
  --build-arg RUST_VERSION=1 \
  --build-arg BUN_VERSION=1 \
  --build-arg UV_VERSION=latest \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  .
```

## Run

```bash
container run --rm -it -v "$PWD:/workspace" base-devel:trixie
```

Or pull a published multi-arch (`linux/amd64`, `linux/arm64`) image from GHCR:

```bash
container run --rm -it -v "$PWD:/workspace" ghcr.io/exzolab/base-devel:latest
```

## Publishing via GitHub Actions

Pushing a `v*` tag (e.g. `v1.0.0`) or triggering **Build and Publish Image** manually builds and publishes multi-arch (`linux/amd64`, `linux/arm64`) images to `ghcr.io/exzolab/base-devel` using `.github/workflows/publish.yml`.
