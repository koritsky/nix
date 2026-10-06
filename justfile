# Deploy per-host home-manager envs with deploy-rs (build output condensed via nom).
#   just deploy            # all hosts in deploy.nodes
#   just deploy .#kitkat   # a single host
#   just deploy .#renate
# pipefail so a failed deploy isn't masked by nom's exit code.
set shell := ["bash", "-o", "pipefail", "-c"]

# Deploy home-manager envs to the fleet (all hosts, or e.g. `.#kitkat`).
deploy *ARGS:
    nix run .#deploy-rs -- {{ ARGS }} -- --log-format internal-json 2>&1 | nix run .#nix-output-monitor -- --json

# Flags: --full (every flake input too), --no-bump, or node names to limit the
# deploy — see the header of update-servers.sh.
#
# Bump claude-code, check, commit, push and deploy to the whole fleet.
update *ARGS:
    ./update-servers.sh {{ ARGS }}

# Refreshes our copy of the upstream release manifest (version + per-platform
# checksums), which modules/shared/claude.nix feeds to nixpkgs' claude-code
# package. Touches nothing else — no flake.lock change — so only claude-code is
# re-fetched on the next rebuild/deploy.
#
# Pin claude-code to Anthropic's newest release.
bump-claude:
    #!/usr/bin/env bash
    set -euo pipefail
    base=https://downloads.claude.ai/claude-code-releases
    version=$(curl -fsSL "$base/latest")
    curl -fsSL "$base/$version/manifest.zst.json" -o files/claude-manifest.json
    echo "claude-code -> $version"

# The expensive one — it re-downloads most of the closure on the Mac and every
# server — so weekly rather than daily; `bump-claude` covers the daily case.
#
# Update every flake input.
bump:
    nix flake update

# Asks for sudo. The servers and the Mac's user profiles expire on their own
# (services.home-manager.autoExpire); system generations don't.
#
# Mac: keep the newest 5 system + user generations, collect the rest.
clean:
    nh clean all --keep 5
