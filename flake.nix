{
  description = "NixOS config of Samuel Recker";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ags.url = "github:aylur/ags";
    astal.url = "github:aylur/astal";
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, ags, astal, ... }:
    let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      overlay-everforest = final: prev: {
        everforest-gtk-theme = prev.everforest-gtk-theme.overrideAttrs (old: {
          version = "0-unstable-2025-10-23";
          src = final.fetchFromGitHub {
            owner = "Fausto-Korpsvart";
            repo = "Everforest-GTK-Theme";
            rev = "9b8be4d6648ae9eaae3dd550105081f8c9054825";
            hash = "sha256-XHO6NoXJwwZ8gBzZV/hJnVq5BvkEKYWvqLBQT00dGdE=";
          };
          nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ final.sassc ];
          installPhase = ''
            runHook preInstall
            mkdir -p "$out/share/"{themes,icons}
            cp -a icons/* "$out/share/icons/"
            bash themes/install.sh --name Everforest --dest "$out/share/themes" --tweaks medium outline -c dark
            runHook postInstall
          '';
        });
      };
    in {
    nixosConfigurations.nexus = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        { nixpkgs.overlays = [ overlay-everforest ]; }
        ./hardware-configuration-nexus.nix
        ./configuration.nix
        { networking.hostName = "nexus";
          boot.resumeDevice = "/dev/disk/by-uuid/e19d076a-d3e1-4031-8ad3-cb81085e4499";
        }
	home-manager.nixosModules.home-manager
	{
	  home-manager.useGlobalPkgs = true;
	  home-manager.useUserPackages = true;
	  home-manager.users.samox = import ./home.nix;
	  home-manager.extraSpecialArgs = { inherit ags astal pkgs-unstable; hostname = "nexus"; };
	}
      ];
    };

    nixosConfigurations.umbreon = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        { nixpkgs.overlays = [ overlay-everforest ]; }
        ./hardware-configuration-umbreon.nix
        ./configuration.nix
        { networking.hostName = "umbreon"; }
	home-manager.nixosModules.home-manager
	{
	  home-manager.useGlobalPkgs = true;
	  home-manager.useUserPackages = true;
	  home-manager.users.samox = import ./home.nix;
	  home-manager.extraSpecialArgs = { inherit ags astal pkgs-unstable; hostname = "umbreon"; };
	}
      ];
    };
  };
}
