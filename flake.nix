{
  description = "Shared CLI environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      mkHome = system: username: homeDirectory:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          modules = [
            ./home.nix
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
              home.stateVersion = "25.05";
            }
          ];
        };
    in {
      homeConfigurations."server-linux" = mkHome "x86_64-linux" "nikita" "/home/nikita";
      homeConfigurations."server-mac"   = mkHome "aarch64-darwin" "nikitaak" "/Users/nikitaak";
    };
}
