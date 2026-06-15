{ pkgs, llm-agents, ... }:

{
  programs.claude-code = {
    enable = true;
    package = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
    settings = {
      model = "claude-opus-4-8";
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
    };
  };

  home.file.".claude/statusline.sh" = {
    executable = true;
    source = ../../files/statusline.sh;
  };
}
