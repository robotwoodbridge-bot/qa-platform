# Security Runner (Kali + ZAP) — isolated network

Isolated on its own network (qa-security-net) by default, deliberately not
connected to net-qa-platform, so a misconfigured scan can't reach other
test containers, and to keep authorized-scan scope explicit for audit
purposes.

To run an authorized scan against a specific target network, attach it
for the session only:

    terraform apply -var 'security_additional_networks=["<target-network>"]'

Then revert (remove the var / apply again with the default empty list) once
the scan is done, rather than leaving the connection in place.

## Docker socket (accepted tradeoff)

security.robot's keywords launch scan tools as ephemeral sibling containers
(`docker run --rm ghcr.io/zaproxy/zaproxy`, `frapsoft/nikto`,
`instrumentisto/nmap`) via Robot's Process library, rather than calling
binaries installed in this image. That requires access to the Docker
daemon, so `/var/run/docker.sock` is mounted into this container.

This is a real tension with the network-isolation goal above: a container
with the Docker socket has root-equivalent control over every other
container on the host, not just what's reachable on qa-security-net — so a
compromise of this container is no longer contained to its own network.
Decided to accept this for now to keep the existing test implementation
working as-is and stay consistent with the docker-exec pattern the other
scripts use. Revisit if this container's threat model changes (e.g. once
this stack runs somewhere other than a local dev machine) — options then
include a remote Docker context instead of the socket, or rewriting the
scan keywords to call a sidecar with a scoped API instead of raw
docker run.
