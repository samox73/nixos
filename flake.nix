{
  description = "NixOS config of Samuel Recker";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-rnote.url = "github:NixOS/nixpkgs/9da7f1cf7f8a6e2a7cb3001b048546c92a8258b4";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ags.url = "github:aylur/ags";
    astal.url = "github:aylur/astal";
  };

  outputs = { nixpkgs, nixpkgs-unstable, nixpkgs-rnote, home-manager, ags, astal, ... }:
    let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-rnote = import nixpkgs-rnote {
        inherit system;
        config.allowUnfree = true;
      };
    in {
    nixosConfigurations.nexus = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit pkgs-unstable; };
      modules = [
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
	  home-manager.extraSpecialArgs = { inherit ags astal pkgs-unstable pkgs-rnote; hostname = "nexus"; };
	}
      ];
    };

    nixosConfigurations.umbreon = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit pkgs-unstable; };
      modules = [
        ./hardware-configuration-umbreon.nix
        ./configuration.nix
        { networking.hostName = "umbreon"; }
	home-manager.nixosModules.home-manager
	{
	  home-manager.useGlobalPkgs = true;
	  home-manager.useUserPackages = true;
	  home-manager.users.samox = import ./home.nix;
	  home-manager.extraSpecialArgs = { inherit ags astal pkgs-unstable pkgs-rnote; hostname = "umbreon"; };
	}
      ];
    };
  };
}
