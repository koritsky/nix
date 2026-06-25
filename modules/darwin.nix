{ ... }:

{
  # No sops on the Macs — secrets are kept as plain files on the machine, not
  # provisioned/decrypted by nix. (Linux servers still use sops.)
  profile.secrets = false;

  home.file.".aerospace.toml".source = ../files/aerospace.toml;
}
