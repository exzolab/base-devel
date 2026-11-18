# base-devel

Multi-toolchain development Docker image based on `debian:trixie-slim`, bundling:

- **Node.js** (`node`, `npm`, `npx`)
- **uv + Python** (`uv`, `uvx`, `python`, `python3`)
- **Bun** (`bun`, `bunx`)
- **Rust + Cargo** (`rustc`, `cargo`, `rustup`)
- **Go** (`go`, `gofmt`)
- Common system build tools (`build-essential`, `git`, `pkg-config`, `libssl-dev`, `curl`, `ca-certificates`, `sudo`, etc.)

## Build

```bash
docker build -t base-devel:trixie .
```

### Customizing Versions or User UID/GID

All toolchain versions and user settings are configurable via `--build-arg`:

```bash
docker build -t base-devel:trixie \
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

### Multi-Architecture Build

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t base-devel:trixie .
```

## Run

```bash
docker run --rm -it -v "$PWD:/workspace" base-devel:trixie
```
