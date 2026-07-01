{ ... }:

{
  imports = [
    ./modules/profile.nix
    ./modules/shared/core.nix
    ./modules/shared/stylix.nix
    ./modules/shared/sops.nix
    ./modules/shared/zsh.nix
    ./modules/shared/git.nix
    ./modules/shared/helix.nix
    ./modules/shared/claude.nix
    ./modules/shared/zellaude.nix
    ./modules/shared/codex.nix
  ];
}
