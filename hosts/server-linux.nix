{ config, lib, ... }:

{
  imports = [
    ../home.nix
    ../modules/linux.nix
  ];

  profile = {
    # mkDefault: hosts built on top of this one (renate, delta-*) set their own,
    # so `nup` there switches to their config rather than this one.
    name = lib.mkDefault "server-linux";
    username = "nikita";
    homeDirectory = "/home/nikita";
  };

  # Personal Rex server as a systemd user service, on the tailnet as its own
  # node (Rex's built-in Tailscale — no tailscaled on the box). Reach it at
  # https://rex-<host>.<tailnet>.ts.net. First start: open the sign-in link
  # from `rex server status` / `journalctl --user -u rex`. Needs
  # `loginctl enable-linger` once so it survives logout. Deploys don't restart
  # a running server (that would end its sessions): `systemctl --user restart
  # rex` picks up a new version.
  services.rex = {
    enable = true;
    tailscale = {
      enable = true;
      hostname = "rex-${config.profile.name}";
    };
  };
}
