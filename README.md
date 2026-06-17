# Unofficial BrowserOS Nix Flake

This is an unofficial flake to package and install [BrowserOS](https://www.browseros.com/) on NixOS.
It currently supports the `x86_64-linux` platform.

## Installation

### 1. Add the Flake to your inputs

Add `browseros-flake` to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    browseros.url = "github:jackdbai/browseros-flake";
  };

  outputs = { self, nixpkgs, browseros, ... }@inputs: {
    # ...
  };
}
```

### 2. Install the Package

There are two common ways to add BrowserOS to your configuration:

#### Option A: Direct Reference
Pass `inputs` to your configuration module (e.g. via `specialArgs` or `extraSpecialArgs`), then reference the package directly:

**NixOS Configuration (`configuration.nix`):**
```nix
{ inputs, pkgs, ... }: {
  environment.systemPackages = [
    inputs.browseros.packages.${pkgs.system}.default
  ];
}
```

**Home Manager Configuration (`home.nix`):**
```nix
{ inputs, pkgs, ... }: {
  home.packages = [
    inputs.browseros.packages.${pkgs.system}.default
  ];
}
```

> [!NOTE]
> Ensure you pass `inputs` from your top-level `flake.nix` to your modules. For NixOS, use `specialArgs = { inherit inputs; };`. For Home Manager, use `extraSpecialArgs = { inherit inputs; };`.

---

#### Option B: Via Overlay (Recommended)
Add the default overlay provided by this flake to your `nixpkgs.overlays`, allowing you to reference the package as `pkgs.browseros` like a standard package.

**NixOS Configuration (`configuration.nix`):**
```nix
{ inputs, pkgs, ... }: {
  nixpkgs.overlays = [
    inputs.browseros.overlays.default
  ];

  environment.systemPackages = [
    pkgs.browseros
  ];
}
```
