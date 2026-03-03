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

    catppuccin-zen-browser-src = {
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

    keyrs = {
      url = "github:higorprado/keyrs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-awww-src = {
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
      lib = nixpkgs.lib;
      devenvTemplateRoot = ./config/devenv-templates;
      devenvTemplateDirs = lib.filterAttrs (_: fileType: fileType == "directory") (
        builtins.readDir devenvTemplateRoot
      );
      devenvTemplateNames = builtins.attrNames devenvTemplateDirs;
      devenvTemplates = lib.genAttrs devenvTemplateNames (name: {
        path = devenvTemplateRoot + "/${name}";
        description = "devenv project template (${name})";
      });
      customPkgs = import ./pkgs {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit inputs;
      };
      llm-agents-pkgs = llm-agents.packages.${system};

      mkHostSystem =
        modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs customPkgs llm-agents-pkgs; };
          inherit modules;
        };

      hostRegistry = {
        predator = [
          inputs.disko.nixosModules.disko
          inputs.niri.nixosModules.niri
          inputs.hyprland.nixosModules.default
          inputs.dms.nixosModules.dank-material-shell
          inputs.dms.nixosModules.greeter
          inputs.home-manager.nixosModules.home-manager
          inputs.keyrs.nixosModules.default

          ./hosts/predator/default.nix
        ];

        server-example = [
          ./hosts/server-example/default.nix
        ];
      };
    in
    {
      templates =
        devenvTemplates
        // lib.optionalAttrs (devenvTemplateDirs ? python) {
          default = devenvTemplates.python;
        };

      nixosConfigurations = lib.mapAttrs (_: modules: mkHostSystem modules) hostRegistry;
    };
}
