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
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
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
      nix-darwin,
      nix-homebrew,
      llm-agents,
      sops-nix,
      stylix,
      deploy-rs,
      updog,
      ...
    }:
    let
      # Home-manager modules common to every host (standalone or via nix-darwin).
      sharedHomeModules = [
        sops-nix.homeManagerModules.sops
        stylix.homeModules.stylix
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
          modules = sharedHomeModules ++ [ hostModule ];
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
      # macOS machine — system + Homebrew + both users' home-manager, applied
      # with `sudo darwin-rebuild switch --flake ~/nix#Nikitas-MacBook-Pro`.
      darwinConfigurations."Nikitas-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit llm-agents; };
        modules = [
          ./modules/darwin-system.nix
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = "kortisky"; # current owner of /opt/homebrew
              autoMigrate = true; # adopt the existing brew install
            };
          }
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak"; # handoff from standalone HM
            home-manager.extraSpecialArgs = { inherit llm-agents; };
            home-manager.sharedModules = sharedHomeModules;
            home-manager.users.nikitaak = import ./hosts/nikitaak.nix;
            home-manager.users.kortisky = import ./hosts/kortisky.nix;
          }
        ];
      };

      homeConfigurations = {
        server-linux = mkHome "x86_64-linux" ./hosts/server-linux.nix;
        # Mac users now deploy via darwinConfigurations above; kept as a
        # standalone fallback during the nix-darwin transition.
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
