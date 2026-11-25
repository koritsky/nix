{ config, ... }:

# ~/.ssh/config on the Mac. No LocalForwards: Rex covers the remote sessions,
# and a one-off `ssh -L 8888:localhost:8888 kitkat` covers the rest.
let
  common = {
    IdentityFile = "~/.ssh/id_rsa";
    ForwardAgent = true;
    AddKeysToAgent = true;
    UseKeychain = true;
    Compression = true;
    ServerAliveInterval = 60;
  };
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # UseKeychain is Apple-only; Nix's OpenSSH (deploy-rs, nix copy) would
    # reject the whole file without this at the top
    extraOptionOverrides.IgnoreUnknown = "UseKeychain";
    includes = [ "${config.home.homeDirectory}/.colima/ssh_config" ];
    settings = builtins.mapAttrs (
      _: HostName:
      common
      // {
        inherit HostName;
        User = "nikita";
      }
    ) (import ../lib/ssh-hosts.nix);
  };
}
