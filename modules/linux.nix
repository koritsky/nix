{ pkgs, ... }:

{
  home.packages = [
    pkgs.nvitop
  ];

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
