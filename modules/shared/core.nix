{ pkgs, ... }:

{
  home.packages = [
    pkgs.age
    pkgs.jq
    pkgs.just
    pkgs.nh
    pkgs.sops
    pkgs.tealdeer
  ];

  programs = {
    home-manager.enable = true;
    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = false;
        sync_frequency = "5m";
        search_mode = "fuzzy";
        filter_mode = "global";
      };
    };
    bat.enable = true;
    eza = {
      enable = true;
      git = true;
      icons = "auto";
    };
    fd.enable = true;
    fzf.enable = true;
    gh.enable = true;
    htop.enable = true;
    lazygit.enable = true;
    ripgrep.enable = true;
    starship = {
      enable = true;
      settings.format = "$directory$git_branch$git_state$nix_shell$python\n$character";
      settings.right_format = "$username$hostname";
    };
    uv.enable = true;
    yazi = {
      enable = true;
      shellWrapperName = "y";
      settings.mgr = {
        show_symlink = true;
        sort_by = "natural";
        linemode = "size";
      };
      plugins = {
        inherit (pkgs.yaziPlugins) rsync;
      };
      keymap.mgr.prepend_keymap = [
        {
          on = [ "R" ];
          run = "plugin rsync";
          desc = "rsync";
        }
      ];
    };
    zellij.enable = true;
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  xdg.configFile."yazi/theme.toml".source = ../../files/yazi-theme.toml;
}
