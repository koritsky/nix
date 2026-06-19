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
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    # Fleet GPU dashboard + Slack alerting (private repo; SSH so it auths with
    # the local key — github: would need a token).
    updog.url = "git+ssh://git@github.com/yaak-ai/updog?ref=main";
    updog.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      llm-agents,
      sops-nix,
      stylix,
      deploy-rs,
      updog,
      ...
    }:
    let
      mkHome =
        system: hostModule:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit llm-agents; };
          modules = [
            sops-nix.homeManagerModules.sops
            stylix.homeModules.stylix
            hostModule
            { home.stateVersion = "26.05"; }
          ];
        };

      mkEnvNode = host: hmConfig: {
        hostname = host;
        sshUser = "nikita";
        sshOpts = [
          "-o"
          "ClearAllForwardings=yes"
          # quiet ssh: ~/.ssh/config sets LogLevel VERBOSE, which spams
          # "Authenticated to…/Transferred:" on every deploy.
          "-o"
          "LogLevel=ERROR"
        ];
        profiles.home = {
          user = "nikita";
          path = deploy-rs.lib.x86_64-linux.activate.home-manager hmConfig;
          remoteBuild = true;
          magicRollback = false;
        };
      };
    in
    {
      homeConfigurations = {
        server-linux = mkHome "x86_64-linux" ./hosts/server-linux.nix;
        nikitaak = mkHome "aarch64-darwin" ./hosts/nikitaak.nix;
        kortisky = mkHome "aarch64-darwin" ./hosts/kortisky.nix;
        renate = mkHome "x86_64-linux" {
          imports = [
            ./hosts/server-linux.nix
            updog.homeModules.default
          ];
          profile.secrets = false;
          services.updog.enable = true;
        };
      };

      deploy.nodes =
        nixpkgs.lib.genAttrs [ "kitkat" "sisyphos" "berghain" "tresor" "aboutblank" ] (
          host: mkEnvNode host self.homeConfigurations.server-linux
        )
        // {
          renate = mkEnvNode "renate" self.homeConfigurations.renate;
        };
    };
}
