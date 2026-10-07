{
  pkgs,
  lib,
  config,
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

  # Three-way merge, so settings changed at runtime (/effort, /model, "always
  # allow") survive a rebuild: `base` is the copy Nix installed last time, so a
  # key that differs from it was changed at runtime and is kept — unless Nix has
  # changed that key too, in which case Nix wins. No base yet (first run) or
  # unreadable JSON → plain install.
  home.activation.claudeWritableSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claudeSettings="$HOME/.claude/settings.json"
    claudeBase="$HOME/.claude/settings.nix-base.json"
    claudeMerged=$(mktemp)
    if [ -s "$claudeSettings" ] && [ -s "$claudeBase" ] \
      && ${lib.getExe pkgs.jq} -n \
        --slurpfile base "$claudeBase" --slurpfile cur "$claudeSettings" --slurpfile new ${settingsFile} '
          $base[0] as $b | $new[0] as $n
          | $n + ($cur[0] | with_entries(select(.key as $k | .value != $b[$k] and $n[$k] == $b[$k])))
        ' > "$claudeMerged" 2>/dev/null; then
      run install -D -m 644 "$claudeMerged" "$claudeSettings"
    else
      run install -D -m 644 ${settingsFile} "$claudeSettings"
    fi
    run install -D -m 644 ${settingsFile} "$claudeBase"
    rm -f "$claudeMerged"
  '';

  programs.claude-code = {
    enable = true;
    # nixpkgs' packaging (unpack Anthropic's prebuilt binary + wrap), but pinned
    # to our own copy of the upstream release manifest so the version doesn't
    # wait on a nixpkgs bump. `just bump-claude` refreshes the manifest.
    package = pkgs.claude-code.override {
      manifest = lib.importJSON ../../files/claude-manifest.json;
    };
    settings = {
      model = "claude-opus-5-5";
      effortLevel = "medium";
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
          "Bash(git push:*)"
          "Bash(git rebase:*)"

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
          "Bash(git reset --hard:*)"
        ];
      };
      statusLine = {
        type = "command";
        command = "bash ~/.claude/statusline.sh";
      };
      outputStyle = "Concise";
      skipWebFetchPreflight = true;
      includeGitInstructions = true;
      preferredNotifChannel = "notifications_disabled";
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
