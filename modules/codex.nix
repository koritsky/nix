{ pkgs, llm-agents, ... }:

{
  programs.codex = {
    enable = true;
    package = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    settings = {
      model = "gpt-5.5";
      model_reasoning_effort = "xhigh";
      plan_mode_reasoning_effort = "xhigh";
      personality = "pragmatic";
      approval_policy = "never";
      sandbox_mode = "danger-full-access";
      web_search = "live";
      # suppress_unstable_features_warning = true;
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
      };
    };
  };
}
