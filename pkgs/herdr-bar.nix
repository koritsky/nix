# herdr-bar (Cmd+K command bar). Built from source instead of the manifest's
# install.sh, which downloads a release binary. The plugin root is $out:
# herdr-plugin.toml plus bin/herdr-bar, matching the manifest's bin/ paths.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "herdr-bar";
  version = "0.12.0";

  src = fetchFromGitHub {
    owner = "jeffarese";
    repo = "herdr-bar";
    tag = "v${finalAttrs.version}";
    hash = "sha256-CYLnUJ7BQZmtnp7X1vtqTxLjEOaWsFQ2bHyghLG8oM0=";
  };

  cargoHash = "sha256-wHAEx9lBsdKGcZjwmMSCECwjn9KR1/9MmsydgQx19oU=";

  # These inspect real processes (start times, a spawned watcher), which the
  # build sandbox doesn't allow.
  checkFlags = [
    "--skip=age::tests::batch_reads_match_one_at_a_time"
    "--skip=age::tests::this_process_has_an_age"
    "--skip=app::tests::a_pane_is_read_once_and_then_ticked_locally"
    "--skip=real_process_keeps_lock_updates_closed_popup_and_stops"
  ];

  postInstall = ''
    install -Dm644 herdr-plugin.toml "$out/herdr-plugin.toml"
  '';

  meta = {
    description = "Cmd+K command bar with agent icons and fuzzy search for Herdr";
    homepage = "https://github.com/jeffarese/herdr-bar";
    license = lib.licenses.mit;
    mainProgram = "herdr-bar";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
