# wsl-rootfs

`wsl-rootfs` is a small Bash utility that converts a container image from a registry into a compressed Linux root filesystem archive (`.tar.gz`) suitable for importing into WSL.

It does this by:
1. Inspecting the image and ensuring there is exactly one `linux/amd64` manifest.
2. Copying the image into a local OCI layout with `skopeo`.
3. Unpacking the filesystem layers with `umoci`.
4. Creating a rootfs archive with ownership and extended attributes preserved.

## Requirements

The script depends on:

- `bash`
- `skopeo`
- `jq`
- `umoci`
- `tar`

## Usage

```bash
./build.bash <image> <tag> [--ocipath <path>] [--rootfspath <path>] --output <path/to/rootfs.tar.gz>
```

### Arguments

- `<image>`: Container image name (for example, `ubuntu` or `ghcr.io/org/image`).
- `<tag>`: Container image tag (for example, `latest`, `24.04`).
- `--output`: **Required.** Output archive path.
- `--ocipath`: Optional path to store OCI image data (default: `~/.oci`).
- `--rootfspath`: Optional temporary unpack directory (default: `~/.rootfs`).

### Example

```bash
./build.bash ubuntu 24.04 --output ./dist/ubuntu-24.04-rootfs.tar.gz
```

## Import into WSL

After producing the archive, import it into WSL from PowerShell:

```powershell
wsl --import Ubuntu2404 C:\WSL\Ubuntu2404 .\ubuntu-24.04-rootfs.tar.gz
```

## GitHub Actions workflow (YAML)

You can automate rootfs archive builds on each push using this workflow:

```yaml
name: Build WSL rootfs

on:
  push:
    branches: ["main"]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y skopeo jq umoci tar

      - name: Build rootfs archive
        run: |
          chmod +x ./build.bash
          ./build.bash ubuntu 24.04 --output ./dist/ubuntu-24.04-rootfs.tar.gz

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ubuntu-24.04-rootfs
          path: ./dist/ubuntu-24.04-rootfs.tar.gz
```

This workflow checks out the repository, installs required tools, runs `build.bash`, and uploads the generated rootfs archive as a downloadable workflow artifact.

## Notes and limitations

- The script currently selects only `amd64` manifests.
- It fails if zero or multiple `amd64` manifests are found.
- Existing unpacked rootfs data for the selected image under `--rootfspath` is deleted before unpacking.

## License

MIT. See [LICENSE](./LICENSE).
