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
      # Module list shared by the standalone homeConfigurations below and by
      # the reusable homeModules output (consumed by twix on the NixOS boxes).
      homeModulesFor = hostModule: [
        sops-nix.homeManagerModules.sops
        stylix.homeModules.stylix
        hostModule
        { home.stateVersion = "26.05"; }
      ];
      mkHome =
        system: hostModule:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit llm-agents; };
          modules = homeModulesFor hostModule;
        };
    in
    {
      homeConfigurations = {
        server-linux = mkHome "x86_64-linux" ./hosts/server-linux.nix;
        laptop = mkHome "aarch64-darwin" ./hosts/laptop.nix;
      };

      # Reusable home-manager module for embedding in a NixOS system that uses
      # home-manager as a NixOS module (e.g. yaak-ai/twix on renate). The
      # consumer supplies pkgs via `home-manager.useGlobalPkgs`; `llm-agents`
      # is injected here so the consumer needn't know about that input.
      homeModules.server-linux = {
        imports = homeModulesFor ./hosts/server-linux.nix;
        _module.args.llm-agents = llm-agents;
      };
    };
}
