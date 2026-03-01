{
  description = "NixOS Config - Predator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
    };

    catppuccinZenBrowserSource = {
      url = "github:catppuccin/zen-browser";
      flake = false;
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    keyrsSource = {
      url = "github:higorprado/keyrs";
      flake = false;
    };

    dmsAwwwSource = {
      url = "github:higorprado/dms-awww-integration";
      flake = false;
    };

    rmpc = {
      url = "github:mierak/rmpc";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zed-editor = {
      url = "github:Rishabh5321/custom-packages-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{ nixpkgs, llm-agents, ... }:
    let
      system = "x86_64-linux";
      customPkgs = import ./pkgs {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit inputs;
      };
      llm-agents-pkgs = llm-agents.packages.${system};
    in
    {
      nixosConfigurations.predator = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs customPkgs llm-agents-pkgs; };
        modules = [
          {
            nix.settings.substituters = [ "https://cache.numtide.com" ];
            nix.settings.trusted-public-keys = [
              "cache.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
            ];
          }
          inputs.disko.nixosModules.disko
          inputs.niri.nixosModules.niri
          inputs.hyprland.nixosModules.default
          inputs.dms.nixosModules.dank-material-shell
          inputs.dms.nixosModules.greeter
          inputs.home-manager.nixosModules.home-manager

          {
            home-manager = {
              extraSpecialArgs = { inherit inputs customPkgs llm-agents-pkgs; };
              sharedModules = [
                inputs.catppuccin.homeModules.catppuccin
              ];
            };
          }

          ./hosts/predator/default.nix
        ];
      };
    };
}
