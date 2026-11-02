{ config, lib, ... }:

let
  envSecrets = import ../../lib/secrets.nix;
in
{
  sops = lib.mkIf config.profile.secrets {
    defaultSopsFile = ../../secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    secrets = lib.genAttrs envSecrets (_: { });
    # wandb reads ~/.netrc when WANDB_API_KEY is unset, so non-interactive
    # shells (ssh cmd, cron, jobs) get the key too — the zsh export only runs
    # in interactive ones.
    templates.netrc = {
      path = "${config.home.homeDirectory}/.netrc";
      mode = "0600";
      content = ''
        machine api.wandb.ai
          login user
          password ${config.sops.placeholder.wandb-api-key}
      '';
    };
  };
}
