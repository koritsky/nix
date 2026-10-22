{ ... }:

{
  programs.codex = {
    enable = true;
    # Write config.toml as a real file (merged with what's there) instead of a
    # read-only store symlink, so Codex can persist "trust this folder?" etc.
    mutableSettings = true;
    settings = {
      personality = "pragmatic";
      approval_policy = "never";
      sandbox_mode = "danger-full-access";
      web_search = "live";
      suppress_unstable_features_warning = true;
      tui = {
        theme = "dracula";
        status_line = [
          "model-with-reasoning"
          "context-remaining"
          "current-dir"
          "git-branch"
          "five-hour-limit"
          "weekly-limit"
          "context-window-size"
          "used-tokens"
        ];
      };
      features = {
        apply_patch_freeform = true;
        fast_mode = true;
        multi_agent = true;
        remote_models = true;
        runtime_metrics = true;
        shell_snapshot = true;
        unified_exec = true;
        goals = true;
        hooks = true;
        memories = true;
        undo = true;
      };
    };
  };
}
