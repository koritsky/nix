{ pkgs, ... }:

{
  home.packages = [
    pkgs.nvitop
  ];

  # Put multi-user Nix on PATH for NON-interactive SSH sessions. deploy-rs runs
  # `nix copy`/`nix-daemon` over ssh, which doesn't read the login profile, so
  # without this the daemon binary isn't found. No-op on NixOS (file absent,
  # Nix already global).
  programs.zsh.envExtra = ''
    [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] \
      && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  '';

  programs.zsh.shellAliases = {
    ntop = "LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1 nvitop -m";
  };

  programs.yazi.keymap.mgr.prepend_keymap = [
    {
      on = [
        "g"
        "n"
      ];
      run = "cd /nasa/drives/yaak/data";
      desc = "/nasa/drives/yaak/data";
    }
  ];
}
