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

  # `<tool> init zsh` output generated once at build time and sourced, instead
  # of forking the tool on every shell start (five forks, ~25 ms). The output
  # doesn't depend on the user's config, only on the package. HOME: atuin wants
  # a writable one to load its (default) settings.
  initScript =
    name: args:
    pkgs.runCommand "${name}-init.zsh" { } ''
      export HOME=$TMPDIR
      ${lib.getExe config.programs.${name}.package} ${args} > $out
    '';
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
    # -C: load ~/.zcompdump as-is, skipping the per-start re-audit of every
    # completion file (~40 ms). It also never prompts about insecure dirs (the
    # multi-user /opt/homebrew completion dir is owned by the other admin user).
    # The dump is rebuilt whenever it's missing, and the activation hook below
    # removes it on each switch so new completions are picked up.
    completionInit = "autoload -Uz compinit && compinit -C";

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
      # Prebuilt replacements for the home-manager zsh integrations switched
      # off below; same guards and ordering as theirs (zoxide 851, fzf 910).
      (lib.mkOrder 851 "source ${initScript "zoxide" "init zsh ${lib.escapeShellArgs config.programs.zoxide.options}"}")
      (lib.mkOrder 910 ''
        if [[ $options[zle] = on ]]; then
          source ${initScript "fzf" "--zsh"}
        fi
      '')
      ''
        if [[ $TERM != "dumb" ]]; then
          source ${initScript "starship" "init zsh --print-full-init"}
        fi
        source ${initScript "direnv" "hook zsh"}
        if [[ $options[zle] = on ]]; then
          source ${initScript "atuin" "init zsh ${lib.escapeShellArgs config.programs.atuin.flags}"}
        fi
      ''
    ];
  };

  programs = {
    atuin.enableZshIntegration = false;
    direnv.enableZshIntegration = false;
    fzf.enableZshIntegration = false;
    starship.enableZshIntegration = false;
    zoxide.enableZshIntegration = false;
  };

  home.activation.resetZcompdump = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run rm -f "$HOME/.zcompdump"
  '';
}
