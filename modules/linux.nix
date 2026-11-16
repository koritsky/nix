{ pkgs, ... }:

{
  home.packages = [
    pkgs.nvitop
  ];

  # No fonts on headless boxes — the terminal font comes from the SSH client.
  # font-packages pulled nerd-fonts.jetbrains-mono plus stylix's default emoji
  # font (noto-fonts-color-emoji) into every server closure: ~1 GB of transfer
  # for nothing. The base16 themes (btop/fzf/starship) only need the font *name*,
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

  programs.zsh.shellAliases =
    let
      # Ubuntu boxes (berghain, delta-*) need the driver's NVML preloaded; the
      # multiarch dir differs by arch (x86_64- vs aarch64-linux-gnu). On the
      # NixOS servers nvitop finds it in /run/opengl-driver on its own.
      nvml = "/usr/lib/${pkgs.stdenv.hostPlatform.parsed.cpu.name}-linux-gnu/libnvidia-ml.so.1";
    in
    {
      ntop = "LD_PRELOAD=$([ -e ${nvml} ] && echo ${nvml}) nvitop -m";
    };

  # Fleet aliases so `ssh kitkat` works server-to-server, not just from the Mac.
  # Auth rides the Mac's forwarded agent; ForwardAgent keeps it alive per hop.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = builtins.mapAttrs (_: HostName: {
      inherit HostName;
      User = "nikita";
      ForwardAgent = true;
    }) (import ../lib/ssh-hosts.nix);
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
