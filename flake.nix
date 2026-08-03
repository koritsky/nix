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

      # deploy-rs's activate binary is a cache miss for us: deploy-rs.inputs.nixpkgs
      # follows ours, so their prebuilt binary doesn't match and every host
      # compiles deploy-rs + ~60 crates from source (~4 min each). nixpkgs' own
      # deploy-rs IS cached, so swap the binary in and keep deploy-rs's activation
      # lib (upstream's documented `deployPkgs` pattern). The lib references
      # `final.deploy-rs.deploy-rs`, hence the overlay fix-point rather than a
      # plain attrset.
      deployLib = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        (import nixpkgs {
          inherit system;
          overlays = [
            deploy-rs.overlays.default
            (_: prev: {
              deploy-rs = prev.deploy-rs // {
                inherit (nixpkgs.legacyPackages.${system}) deploy-rs;
              };
            })
          ];
        }).deploy-rs.lib
      );

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

      # Shared config for the aarch64 delta boxes (delta-dev1/delta-emc1).
      mkDelta = mkHome "aarch64-linux" {
        imports = [ ./hosts/server-linux.nix ];
        profile.secrets = false;
        profile.llmAgents = false;
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
            path = deployLib.${system}.activate.home-manager hmConfig;
            remoteBuild = true;
            magicRollback = false;
          };
        };
    in
    {
      # Tools used by the justfile, taken from our locked nixpkgs because they are
      # cached there. `github:serokell/deploy-rs#default` is a cache miss on both
      # cache.nixos.org and deploy-rs.cachix.org, so `nix run`ing it compiled the
      # CLI from source here on every deploy; this also keeps the CLI in lockstep
      # with the activate binary that `deployLib` bakes into each profile.
      packages.aarch64-darwin = {
        inherit (nixpkgs.legacyPackages.aarch64-darwin) deploy-rs nix-output-monitor;
      };

      # Prebuilt binaries that live ONLY in cache.numtide.com. The servers'
      # /etc/nix/nix.conf lists just cache.nixos.org, and deploy-rs's remote build
      # substitutes using the *remote daemon's* config — client-side
      # `--option extra-substituters` is silently ignored, and this flake's
      # `nixConfig` never applies either because deploy-rs builds a bare .drv path
      # with no flake in scope. So without `just seed` every host compiles codex
      # from source (~12 min each). Only x86_64: the aarch64 delta boxes set
      # profile.llmAgents = false and take claude-code from nixpkgs.
      # unsafeDiscardStringContext: we want the path *names* to hand to `nix copy`,
      # not the built paths — with the context attached, `nix eval --raw` tries to
      # realise codex here on the Mac (and fails, it's x86_64-linux).
      seedPaths.x86_64-linux = builtins.unsafeDiscardStringContext (
        nixpkgs.lib.concatStringsSep " " [
          "${llm-agents.packages.x86_64-linux.codex}"
          "${llm-agents.packages.x86_64-linux.claude-code}"
        ]
      );

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
        # aarch64 delta boxes (NVIDIA Jetson / Ubuntu). Secrets off until the age
        # key is on the box — flip profile.secrets once
        # ~/.config/sops/age/keys.txt exists. llmAgents off: llm-agents'
        # wrap-buddy ELF patcher fails on aarch64.
        delta-dev1 = mkDelta;
        delta-emc1 = mkDelta;
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
          host:
          mkEnvNode {
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
          delta-emc1 = mkEnvNode {
            host = "delta-emc1";
            system = "aarch64-linux";
            hmConfig = self.homeConfigurations.delta-emc1;
          };
        };
    };
}
