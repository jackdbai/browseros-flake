# ABOUT
This is an unofficial flake to install [BrowserOS](https://www.browseros.com/) on NixOS.
It currently builds only for `x86_64-linux` systems.

# HOWTO
1. In your `flake.nix`, make sure you have the inputs and outputs set correctly:
```nix
{
  description = "I <3 Nix";

  inputs = {
    browseros.url = "github:jackdbai/browseros-flake";
    # THE REST OF YOUR INPUTS GO HERE
  };

  outputs = { self, browseros, home-manager, hosts, nixpkgs, ... } @ inputs: {
    # THE REST OF YOUR NORMAL CONFIGS GO HERE
  };
}
```
2. In wherever you list your installed packages (I use home-manager), include the reference to the flake:
```nix
{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    inputs.browseros.packages."${system}".default
    # OTHER PACKAGES GO HERE
  ];
}
```
