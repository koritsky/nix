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

      sharedOverlays = [
        (_: prev: {
          # afdko's test suite is broken on current nixpkgs-unstable (93 failures
          # in addfeatures/makeotf). It's pulled in transitively by stylix's
          # default emoji font (noto-fonts-color-emoji → nototools → afdko), so
          # without this every build that includes the emoji font fails. The tool
          # builds fine; only the checkPhase is broken — skip it. afdko lives in
          # the python package set, so override it for every python via
          # pythonPackagesExtensions.
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (_: pyprev: {
              afdko = pyprev.afdko.overridePythonAttrs (_: { doCheck = false; });
            })
          ];
        })
      ];

      mkHome =
        system: hostModule:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = sharedOverlays;
          };
          extraSpecialArgs = { inherit llm-agents; };
          modules = sharedHomeModules ++ [ hostModule ];
        };

      # system defaults to x86_64-linux (the bulk of the fleet); pass
      # aarch64-linux for ARM boxes (e.g. the Jetson delta-dev1).
      mkEnvNode =
        {
          host,
          hmConfig,
          system ? "x86_64-linux",
        }:
        {
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
            path = deploy-rs.lib.${system}.activate.home-manager hmConfig;
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
          { nixpkgs.overlays = sharedOverlays; }
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
            home-manager.backupFileExtension = "pre-darwin"; # fresh ext: avoid colliding with stale *.hm-bak
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
        # NVIDIA Jetson (aarch64 Ubuntu). Secrets off until the age key is on
        # the box — flip profile.secrets once ~/.config/sops/age/keys.txt exists.
        # llmAgents off: llm-agents' wrap-buddy ELF patcher fails on aarch64.
        delta-dev1 = mkHome "aarch64-linux" {
          imports = [ ./hosts/server-linux.nix ];
          profile.secrets = false;
          profile.llmAgents = false;
        };
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
          host: mkEnvNode {
            inherit host;
            hmConfig = self.homeConfigurations.server-linux;
          }
        )
        // {
          renate = mkEnvNode {
            host = "renate";
            hmConfig = self.homeConfigurations.renate;
          };
          delta-dev1 = mkEnvNode {
            host = "delta-dev1";
            system = "aarch64-linux";
            hmConfig = self.homeConfigurations.delta-dev1;
          };
        };
    };
}
