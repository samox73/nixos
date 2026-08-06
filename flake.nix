{
  description = "NixOS config of Samuel Recker";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvim-config = {
      url = "github:samox73/nvim/main";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { nixpkgs, nixpkgs-unstable, nvim-config, home-manager, rust-overlay, ... }:
    let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
    nixosConfigurations.alakazam = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit pkgs-unstable; };
      modules = [
        ({ ... }: { nixpkgs.overlays = [ rust-overlay.overlays.default ]; })
        ./hardware-configuration-alakazam.nix
        ./configuration.nix
        { networking.hostName = "alakazam";
          boot.resumeDevice = "/dev/disk/by-uuid/e19d076a-d3e1-4031-8ad3-cb81085e4499";
        }
	home-manager.nixosModules.home-manager
	{
	  home-manager.useGlobalPkgs = true;
	  home-manager.useUserPackages = true;
	  home-manager.users.samox = import ./home.nix;
	  home-manager.extraSpecialArgs = { inherit pkgs-unstable nvim-config; hostname = "alakazam"; };
	}
      ];
    };

    nixosConfigurations.umbreon = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit pkgs-unstable; };
      modules = [
        ({ ... }: { nixpkgs.overlays = [ rust-overlay.overlays.default ]; })
        ./hardware-configuration-umbreon.nix
        ./configuration.nix
        { networking.hostName = "umbreon"; }
	home-manager.nixosModules.home-manager
	{
	  home-manager.useGlobalPkgs = true;
	  home-manager.useUserPackages = true;
	  home-manager.users.samox = import ./home.nix;
	  home-manager.extraSpecialArgs = { inherit pkgs-unstable nvim-config; hostname = "umbreon"; };
	}
      ];
    };
  };
}
