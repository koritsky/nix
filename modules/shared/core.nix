{ pkgs, config, ... }:

{
  programs.zsh.shellAliases.nup =
    "git -C ~/nix pull && home-manager switch -b backup --flake ~/nix#${config.profile.name}";

  # Auto-accept flake nixConfig (e.g. rmind/rbyte's extra-substituters) so
  # direnv doesn't hang on the interactive accept prompt. Written directly:
  # home-manager's nix.settings would require a `nix.package`, pulling a second
  # nix into the profile — unwanted on these system/determinate-nix hosts.
  # experimental-features etc. live in the system nix.conf, so this is additive.
  home.file.".config/nix/nix.conf".text = ''
    accept-flake-config = true
  '';

  # Silence direnv's per-cd "direnv: loading/export …" chatter. (programs.direnv
  # `silent` is a no-op in this HM version; setting the env var directly works.)
  home.sessionVariables.DIRENV_LOG_FORMAT = "";

  home.packages = [
    pkgs.age
    pkgs.jq
    pkgs.just
    pkgs.nh
    pkgs.prek
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
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
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
