# blacksmith-cli.nix

Nix flake for the [Blacksmith CLI](https://docs.blacksmith.sh/blacksmith-cli/overview),
packaged from upstream's prebuilt binaries.

Systems: `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`.

## Usage

Run once:

```sh
nix run github:jcmfernandes/blacksmith-cli.nix
```

Install:

```sh
nix profile install github:jcmfernandes/blacksmith-cli.nix
```

Or add the overlay to a flake:

```nix
{
  inputs.blacksmith-cli.url = "github:jcmfernandes/blacksmith-cli.nix";

  # ...
  nixpkgs.overlays = [inputs.blacksmith-cli.overlays.default];
  environment.systemPackages = [pkgs.blacksmith-cli];
}
```

The package is unfree. The flake's own outputs allow it; through the overlay,
allow it in your nixpkgs config.

## Notes

- Auto-update is disabled (`BLACKSMITH_DISABLE_AUTO_UPDATE=1`); the Nix store
  is read-only.
- `rsync` and `openssh` are on the wrapper's `PATH` as a fallback, for
  `testbox`.
- Shell completions for bash, zsh and fish are installed.

## Updates

A daily GitHub Actions job runs `scripts/update.sh`, builds, and commits new
releases. To bump manually:

```sh
scripts/update.sh
```
