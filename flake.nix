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
    in {
    nixosConfigurations.nexus = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
	home-manager.nixosModules.home-manager
	{
	  home-manager.useGlobalPkgs = true;
	  home-manager.useUserPackages = true;
	  home-manager.users.samox = import ./home.nix;
	  home-manager.extraSpecialArgs = { inherit ags astal pkgs-unstable; };
	}
      ];
    };
  };
}
