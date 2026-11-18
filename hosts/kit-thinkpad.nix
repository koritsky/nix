{ ... }:

{
  # Ubuntu laptop. Shared modules only — not server-linux.nix / modules/linux.nix
  # (Rex server, linger, fleet SSH aliases, /nasa keymap, no fonts).
  imports = [ ../home.nix ];

  profile = {
    name = "kit-thinkpad";
    username = "kit-thinkpad";
    homeDirectory = "/home/kit-thinkpad";
    # secrets = false; # until ~/.config/sops/age/keys.txt is on the laptop
  };

  # Non-NixOS desktop: XDG_DATA_DIRS etc., so Nix-installed apps show up in the
  # launcher.
  targets.genericLinux.enable = true;
}
