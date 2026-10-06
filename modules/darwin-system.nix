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
    ];
  };

  # Don't run compinit in the system /etc/zshrc — home-manager handles it (with
  # -i). Avoids the "insecure directories" prompt caused by the multi-user
  # Homebrew (/opt/homebrew is owned by kortisky, group-writable for admin).
  programs.zsh.enableGlobalCompInit = false;

  # nix-darwin's default loads the `suse` prompt theme in every interactive
  # shell (~13 ms); starship replaces it straight after.
  programs.zsh.promptInit = "";

  # nix-homebrew's integration is `eval "$(brew shellenv)"`: a fork of brew on
  # every interactive shell (~10 ms) to print the same few lines, and it puts
  # Homebrew *first* on PATH — so the stale brew copies of hx, zellij, yazi,
  # zoxide, fzf, uv, just and lazygit shadowed the Nix ones in every terminal.
  # Set the same environment here instead, with Homebrew slotted in after the
  # Nix profile dirs and ahead of the system ones (likewise for completions).
  # Remove-then-insert, so shells nested in an older session get reordered too.
  nix-homebrew.enableZshIntegration = false;
  programs.zsh.interactiveShellInit = ''
    if [[ -z ''${HOMEBREW_PREFIX-} ]]; then
      export HOMEBREW_PREFIX="/opt/homebrew"
      export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
      export HOMEBREW_REPOSITORY="/opt/homebrew/Library/.homebrew-is-managed-by-nix"
      export INFOPATH="/opt/homebrew/share/info:''${INFOPATH:-}"
    fi
    [ -z "''${MANPATH-}" ] || { export MANPATH="''${MANPATH%"''${MANPATH##*[!:]}"}"; export MANPATH=":''${MANPATH#"''${MANPATH%%[!:]*}"}"; }
    path=(''${path:#/opt/homebrew/(bin|sbin)})
    path[''${path[(i)/usr/*]},0]=(/opt/homebrew/bin /opt/homebrew/sbin)
    fpath=(''${fpath:#/opt/homebrew/share/zsh/site-functions})
    fpath[''${fpath[(i)/usr/*]},0]=(/opt/homebrew/share/zsh/site-functions)
    export FPATH
  '';

  # Used by `darwin-rebuild` to track the schema; bump only per release notes.
  system.stateVersion = 6;
}
