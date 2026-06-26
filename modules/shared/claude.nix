{
  pkgs,
  lib,
  config,
  llm-agents,
  ...
}:

let
  # Claude Code writes runtime state (effort level, etc.) back into settings.json.
  # The home-manager module links it as a read-only /nix/store symlink, so those
  # writes fail silently and e.g. effortLevel never applies. Instead we disable the
  # module's symlink and install a writable copy of the same generated file.
  settingsFile = (pkgs.formats.json { }).generate "claude-code-settings.json" (
    config.programs.claude-code.settings
    // {
      "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    }
  );
in
{
  # Key must match the module's own home.file entry ("${cfg.configDir}/settings.json",
  # an absolute path) — disabling the relative ".claude/settings.json" no longer matches.
  home.file."${config.programs.claude-code.configDir}/settings.json".enable = lib.mkForce false;

  home.activation.claudeWritableSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run install -D -m 644 ${settingsFile} "$HOME/.claude/settings.json"
  '';

  programs.claude-code = {
    enable = true;
    # llm-agents' claude-code is wrapped with wrap-buddy, which can't build on
    # aarch64 — fall back to nixpkgs' (functionally identical) package there.
    package =
      if config.profile.llmAgents then
        llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
      else
        pkgs.claude-code;
    settings = {
      model = "claude-opus-4-8";
      effortLevel = "xhigh";
      permissions = {
        defaultMode = "auto";
        allow = [
          # navigation & search
          "Bash(ls:*)"
          "Bash(find:*)"
          "Bash(grep:*)"
          "Bash(rg:*)"
          "Bash(cat:*)"
          "Bash(sed:*)"
          "Bash(head:*)"
          "Bash(tail:*)"
          "Bash(wc:*)"
          "Bash(diff:*)"
          "Bash(which:*)"
          "Bash(echo:*)"
          "Bash(cd:*)"

          # git (read + safe writes)
          "Bash(git status:*)"
          "Bash(git log:*)"
          "Bash(git diff:*)"
          "Bash(git show:*)"
          "Bash(git branch:*)"
          "Bash(git add:*)"
          "Bash(git commit:*)"
          "Bash(git checkout:*)"
          "Bash(git stash:*)"
          "Bash(git fetch:*)"
          "Bash(git pull:*)"

          # node / python / nix dev
          "Bash(npm run:*)"
          "Bash(npm install:*)"
          "Bash(npx:*)"
          "Bash(node:*)"
          "Bash(python:*)"
          "Bash(python3:*)"
          "Bash(pip:*)"
          "Bash(uv:*)"
          "Bash(nix build:*)"
          "Bash(nix flake:*)"
          "Bash(nix fmt:*)"
          "Bash(just:*)"
          "Bash(nvidia-smi:*)"

          # linting / formatting
          "Bash(ruff:*)"
          "Bash(black:*)"
          "Bash(prettier:*)"
          "Bash(eslint:*)"
          "Bash(mypy:*)"
          "Bash(tsc:*)"

          # testing
          "Bash(pytest:*)"
          "Bash(jest:*)"
          "Bash(cargo test:*)"

          # misc safe utils
          "Bash(jq:*)"
          "Bash(yq:*)"
          "Bash(curl:*)"
          "Bash(mkdir:*)"
          "Bash(cp:*)"
          "Bash(mv:*)"
          "Bash(date:*)"
          "Bash(env:*)"

          # web
          "WebFetch(*)"
          "WebSearch(*)"
        ];
        deny = [
          "Bash(rm:*)"
          "Bash(sudo:*)"
          "Bash(chmod:*)"
          "Bash(chown:*)"
          "Bash(dd:*)"
          "Bash(mkfs:*)"
          "Bash(git push:*)"
          "Bash(git rebase:*)"
          "Bash(git reset --hard:*)"
        ];
      };
      statusLine = {
        type = "command";
        command = "bash ~/.claude/statusline.sh";
      };
      autoUpdatesChannel = "stable";
      outputStyle = "Concise";
      skipWebFetchPreflight = true;
      includeGitInstructions = true;
      preferredNotifChannel = "iterm2";
      cleanupPeriodDays = 30;
      attribution = {
        commit = "";
        pr = "";
      };
    };
  };

  home.file.".claude/statusline.sh" = {
    executable = true;
    source = ../../files/statusline.sh;
  };
}
