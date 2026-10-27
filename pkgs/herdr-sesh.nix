# From egorchakov/nix-config (pkgs/herdr-sesh.nix). The plugin root is $out:
# herdr-plugin.toml plus bin/herdr-sesh, matching the manifest's ./bin paths.
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  git,
  zoxide,
  eza,
}:
buildGoModule (finalAttrs: {
  pname = "herdr-sesh";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "fullerzz";
    repo = "herdr-plugin-sesh";
    tag = "v${finalAttrs.version}";
    hash = "sha256-sHqlqQWoPWOJTVBlEvV6js0Wwk6ehMoa6uJx07Cg0+g=";
  };

  vendorHash = "sha256-3v8D4Gblg/4REwiYCCPaDete8K+6ngzvdWnfJjbQ+O4=";
  subPackages = [ "cmd/herdr-sesh" ];

  nativeBuildInputs = [ makeWrapper ];

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/fullerzz/herdr-plugin-sesh/internal/app.Version=${finalAttrs.version}"
  ];

  postInstall = ''
    install -Dm644 herdr-plugin.toml "$out/herdr-plugin.toml"
    wrapProgram "$out/bin/herdr-sesh" \
      --prefix PATH : ${
        lib.makeBinPath [
          git
          zoxide
          eza
        ]
      }
  '';

  meta = {
    description = "Sesh-style workspace and session manager for Herdr";
    homepage = "https://github.com/fullerzz/herdr-plugin-sesh";
    license = lib.licenses.mit;
    mainProgram = "herdr-sesh";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
