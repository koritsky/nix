{ ... }:

{
  # Determinate Nix manages Nix on this machine, so nix-darwin must NOT touch
  # /etc/nix or the daemon. (Required when Determinate is installed.)
  nix.enable = false;

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Needed by home-manager (folded in below) and Homebrew.
  system.primaryUser = "nikitaak";
  users.users.nikitaak.home = "/Users/nikitaak";
  users.users.kortisky.home = "/Users/kortisky";

  # Declarative Homebrew casks (GUI apps that want a stable /Applications path,
  # e.g. AeroSpace, whose Accessibility permission is tied to that path).
  # nix-homebrew (wired in flake.nix) provides/owns the brew prefix itself.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none"; # don't remove casks installed outside this list
    };
    casks = [
      "aerospace"
      # OrbStack: lightweight Docker/Linux VM. Bundles the `docker` CLI, so no
      # separate daemon setup — just launch OrbStack.app once.
      "orbstack"
    ];
  };

  # Don't run compinit in the system /etc/zshrc — home-manager handles it (with
  # -i). Avoids the "insecure directories" prompt caused by the multi-user
  # Homebrew (/opt/homebrew is owned by kortisky, group-writable for admin).
  programs.zsh.enableGlobalCompInit = false;

  # Used by `darwin-rebuild` to track the schema; bump only per release notes.
  system.stateVersion = 6;
}
