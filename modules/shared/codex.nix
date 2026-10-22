{ config, lib, ... }:

let
  # config.toml is a read-only store symlink, so Codex can't persist the
  # "trust this folder?" answer itself — declare trusted roots here instead.
  trustedProjects = [
    "${config.home.homeDirectory}/coppernic/coppernic-main"
  ];
in
{
  programs.codex = {
    enable = true;
    settings = {
      projects = lib.genAttrs trustedProjects (_: { trust_level = "trusted"; });
      model = "gpt-5.5";
      model_reasoning_effort = "xhigh";
      plan_mode_reasoning_effort = "xhigh";
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
