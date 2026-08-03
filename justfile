# Deploy per-host home-manager envs with deploy-rs (build output condensed via nom).
#   just deploy            # all hosts in deploy.nodes
#   just deploy .#kitkat   # a single host
#   just deploy .#renate
# pipefail so a failed deploy isn't masked by nom's exit code.
set shell := ["bash", "-o", "pipefail", "-c"]

# x86_64 hosts sharing the server-linux env; targets for `just seed`.
linux_hosts := "kitkat sisyphos berghain tresor aboutblank renate"

deploy *ARGS: seed
    nix run .#deploy-rs -- {{ ARGS }} -- --log-format internal-json 2>&1 | nix run .#nix-output-monitor -- --json

# Stream the numtide-only prebuilt binaries (codex, claude-code) into each host's
# store before deploying — see `seedPaths` in flake.nix for why the servers can't
# fetch them themselves. ~20s per host, versus ~12min compiling codex on each.
# Missing/unreachable hosts only warn: a box being down must not block a deploy.
#
# Delete this recipe (and seedPaths) once cache.numtide.com + its public key are
# in the servers' /etc/nix/nix.conf, which is the real fix — that file is
# Ansible-managed, hence this workaround living here.
seed:
    #!/usr/bin/env bash
    set -uo pipefail
    paths=$(nix eval --raw .#seedPaths.x86_64-linux) || exit 1
    export NIX_SSHOPTS="-o ClearAllForwardings=yes -o LogLevel=ERROR -o ConnectTimeout=10"
    for h in {{ linux_hosts }}; do
      nix copy --from https://cache.numtide.com --to "ssh://nikita@$h" --no-check-sigs $paths \
        || echo "seed: skipped $h (unreachable or copy failed)" >&2
    done
