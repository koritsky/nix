{
  config,
  lib,
  pkgs,
  ...
}:

let
  envSecrets = import ../../lib/secrets.nix;

  # iTerm2 shell integration (prompt marks, command status, `it2*` helpers).
  # Pinned by hash; re-fetch + update the hash if iTerm changes the script.
  itermIntegration = pkgs.fetchurl {
    url = "https://iterm2.com/shell_integration/zsh";
    hash = "sha256-kQJ8bVIh7nEjYJ6OWqiEDqIY+YWD5RbD1CXV+KKyDno=";
  };
  secretToEnv = name: lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] name);
  # Gated on profile.secrets: when secrets are disabled, config.sops.secrets is
  # empty, so referencing it would error — lib.optionalString keeps it lazy.
  exportSecrets = lib.optionalString config.profile.secrets (
    lib.concatMapStringsSep "\n" (
      name:
      let
        path = config.sops.secrets.${name}.path;
      in
      "[ -r ${path} ] && export ${secretToEnv name}=\"$(cat ${path})\""
    ) envSecrets
  );
in
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    # -i: skip insecure fpath dirs instead of prompting (the multi-user
    # /opt/homebrew completion dir is owned by the other admin user).
    completionInit = "autoload -Uz compinit && compinit -i";

    shellAliases = {
      zl = "zellij";
      zlm = "zl a main";
      zla = "zl a --index 0";
      ysudo = "sudo yazi";
    };

    initContent = lib.mkMerge [
      (builtins.readFile ../../files/zsh-init.sh)
      exportSecrets
      # Source iTerm2 shell integration only in iTerm sessions: TERM_PROGRAM
      # locally, LC_TERMINAL over SSH (iTerm forwards LC_*). No-op elsewhere;
      # the script also self-guards on interactive/non-tmux shells.
      ''
        if [ "$TERM_PROGRAM" = "iTerm.app" ] || [ "$LC_TERMINAL" = "iTerm2" ]; then
          source ${itermIntegration}
        fi
      ''
    ];
  };
}
