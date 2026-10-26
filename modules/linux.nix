{ pkgs, ... }:

{
  home.packages = [
    pkgs.nvitop
  ];

  # No fonts on headless boxes — the terminal font comes from the SSH client.
  # font-packages pulled nerd-fonts.jetbrains-mono plus stylix's default emoji
  # font (noto-fonts-color-emoji) into every server closure: ~1 GB of transfer
  # for nothing. The base16 themes (helix/zellij/bat) only need the font *name*,
  # which stylix.fonts still provides.
  stylix.targets = {
    font-packages.enable = false;
    fontconfig.enable = false;
  };

  # Put multi-user Nix on PATH for NON-interactive SSH sessions. deploy-rs runs
  # `nix copy`/`nix-daemon` over ssh, which doesn't read the login profile, so
  # without this the daemon binary isn't found. No-op on NixOS (file absent,
  # Nix already global).
  programs.zsh.envExtra = ''
    [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] \
      && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  '';

  programs.zsh.shellAliases = {
    # Debian/Ubuntu multiarch dir differs by arch (x86_64- vs aarch64-linux-gnu).
    ntop = "LD_PRELOAD=/usr/lib/${pkgs.stdenv.hostPlatform.parsed.cpu.name}-linux-gnu/libnvidia-ml.so.1 nvitop -m";
  };

  # Fleet aliases so `ssh kitkat` works server-to-server, not just from the Mac.
  # Auth rides the Mac's forwarded agent; ForwardAgent keeps it alive per hop.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings =
      builtins.mapAttrs
        (_: HostName: {
          inherit HostName;
          User = "nikita";
          ForwardAgent = true;
        })
        {
          kitkat = "192.168.207.239";
          sisyphos = "192.168.207.241";
          renate = "192.168.207.246";
          berghain = "192.168.207.244";
          tresor = "192.168.207.242";
          aboutblank = "192.168.207.247";
          delta-dev1 = "192.168.144.35";
          delta-emc1 = "172.30.0.40";
        };
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
