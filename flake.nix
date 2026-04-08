{
  description = "Shared CLI environment";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    llm-agents.url = "github:numtide/llm-agents.nix";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      llm-agents,
      sops-nix,
      stylix,
      ...
    }:
    let
      mkHome =
        system: username: homeDirectory:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit llm-agents; };
          modules = [
            sops-nix.homeManagerModules.sops
            stylix.homeModules.stylix
            ./home.nix
            {
              home = {
                username = username;
                homeDirectory = homeDirectory;
                stateVersion = "26.05";
              };
            }
          ];
        };
    in
    {
      homeConfigurations."server-linux" = mkHome "x86_64-linux" "nikita" "/home/nikita";
      homeConfigurations."server-mac" = mkHome "aarch64-darwin" "nikitaak" "/Users/nikitaak";
    };
}
