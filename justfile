# Deploy per-host home-manager envs with deploy-rs.
#   just deploy            # all hosts in deploy.nodes
#   just deploy .#kitkat   # a single host
#   just deploy .#renate
deploy *ARGS:
    nix run github:serokell/deploy-rs -- {{ ARGS }}
