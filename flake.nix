{
  description = "Sid's trying to be advanced nix flake";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixard = {
      url = "github:manelinux/nixard";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    greyline = {
      url = "github:cothinking-dev/greyline";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";
  };

  outputs =
    {
      self,
      nixpkgs-unstable,
      home-manager,
      noctalia,
      agenix,
      nixvim,
      flatpaks,
      hermes-agent,
      nixard,
      stylix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs-unstable.lib;

      # Home Manager modules shared across all workstations
      baseHmImports = [
        ./home/common.nix
        ./home/zsh.nix
        ./home/niri.nix
        ./home/steam.nix
        ./home/greyline.nix
        ./modules/emacs/hm.nix
      ];

      mkWorkstation =
        {
          deviceModule,
          extraHmImports ? [ ], # Machine/role specific HM modules
          extraModules ? [ ], # Extra NixOS system modules
        }:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            deviceModule
            home-manager.nixosModules.home-manager
            flatpaks.nixosModules.default
            agenix.nixosModules.default
            stylix.nixosModules.stylix
            inputs.hermes-agent.nixosModules.default
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs; };

                sharedModules = [
                  (
                    { osConfig, ... }:
                    {
                      _module.args.hostName = osConfig.networking.hostName;
                    }
                  )
                ];

                users.sid = {
                  imports = baseHmImports ++ extraHmImports;
                };
              };
            }
          ]
          ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        prometheus = mkWorkstation {
          deviceModule = ./devices/laptop/prometheus/default.nix;
        };

        karuppu = mkWorkstation {
          deviceModule = ./devices/desktop/karuppu/default.nix;
        };

        mactheus = mkWorkstation {
          deviceModule = ./devices/laptop/mactheus/default.nix;
        };
      };
    };
}
