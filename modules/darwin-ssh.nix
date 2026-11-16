{ config, lib, ... }:

# ~/.ssh/config on the Mac. No LocalForwards: Rex covers the remote sessions,
# and a one-off `ssh -L 8888:localhost:8888 kitkat` covers the rest.
let
  # Shared by the fleet and the root-login delta boxes.
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
    includes = [ "${config.home.homeDirectory}/.colima/ssh_config" ];
    settings =
      builtins.mapAttrs (
        _: HostName:
        common
        // {
          inherit HostName;
          User = "nikita";
        }
      ) (import ../lib/ssh-hosts.nix)
      //
        lib.mapAttrs
          (
            _: HostName:
            common
            // {
              inherit HostName;
              User = "root";
            }
          )
          {
            delta-d12 = "172.30.0.169";
            delta-e20 = "172.30.0.177";
          }
      // {
        delta-evgenii.HostName = "172.30.0.132";
      };
  };
}
