# Deploy per-host home-manager envs with deploy-rs (build output condensed via nom).
#   just deploy            # all hosts in deploy.nodes
#   just deploy .#kitkat   # a single host
#   just deploy .#renate
# pipefail so a failed deploy isn't masked by nom's exit code.
set shell := ["bash", "-o", "pipefail", "-c"]

deploy *ARGS:
    nix run github:serokell/deploy-rs -- {{ ARGS }} -- --log-format internal-json 2>&1 | nix run nixpkgs#nix-output-monitor -- --json
