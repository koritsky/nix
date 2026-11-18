{ ... }:

{
  # Ubuntu laptop. Shared modules only — not server-linux.nix / modules/linux.nix
  # (Rex server, linger, fleet SSH aliases, /nasa keymap, no fonts).
  imports = [ ../home.nix ];

  profile = {
    name = "kit-thinkpad";
    username = "kit";
    homeDirectory = "/home/kit";
    secrets = false; # until ~/.config/sops/age/keys.txt is on the laptop
  };

  # Non-NixOS desktop: XDG_DATA_DIRS etc., so Nix-installed apps show up in the
  # launcher.
  targets.genericLinux.enable = true;

  # Ghostty from nixpkgs. Themed and fonted by stylix. Needs the GPU drivers
  # that targets.genericLinux.gpu (on by default above) links in — one-time
  # `sudo …/non-nixos-gpu-setup`, printed by the first activation.
  programs.ghostty.enable = true;
  stylix.targets.ghostty.enable = true; # stylix autoEnable is off (shared/stylix.nix)
}
