{
  config,
  lib,
  pkgs,
  ...
}:

# From egorchakov/nix-config (modules/home/herdr/plugins.nix). home-manager's
# herdr module has no plugin support, so this adds `programs.herdr.plugins` and
# writes herdr's plugins.json registry from it on every activation.
let
  cfg = config.programs.herdr;
  registry = pkgs.runCommand "herdr-plugins.json" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 - ${lib.escapeShellArgs (map toString cfg.plugins)} > "$out" <<'PY'
    import json
    import sys
    import tomllib
    from pathlib import Path

    entries = []
    for root in sys.argv[1:]:
        manifest_path = Path(root) / "herdr-plugin.toml"
        with manifest_path.open("rb") as f:
            manifest = tomllib.load(f)
        entries.append({
            "plugin_id": manifest["id"],
            "name": manifest["name"],
            "version": manifest["version"],
            "min_herdr_version": manifest.get("min_herdr_version", ""),
            "manifest_path": str(manifest_path),
            "plugin_root": root,
            "enabled": True,
            "source": {"kind": "local"},
        })

    entries.sort(key=lambda entry: entry["plugin_id"])
    json.dump(entries, sys.stdout, indent=2)
    sys.stdout.write("\n")
    PY
  '';
in
{
  options.programs.herdr.plugins = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = ''
      Plugins to register declaratively. Each package must contain
      herdr-plugin.toml at its root. Manifest build commands are not run.
      This list replaces the plugin registry on every activation.
    '';
  };

  config = lib.mkIf cfg.enable {
    home.activation.herdrPluginRegistry = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.coreutils}/bin/install -Dm644 ${registry} \
        ${lib.escapeShellArg "${config.xdg.configHome}/herdr/plugins.json"}
    '';
  };
}
