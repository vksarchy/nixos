# agenix whitelist: which keys can decrypt which secret.
# Run `agenix -e <name>.age` from this directory (or repo root via the bridge).
#
# NOTE: mactheus has no host key here yet. Before using any secret on
# mactheus: ssh-keyscan -t ed25519 mactheus, add it below, then `agenix --rekey`.
#
# secrets/archive/ holds secrets for retired servers (borg passphrases kept in
# case old backup data is ever needed) — intentionally not listed here.
let
  prometheus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHuCNbTo91pcm0yivwv8eOFDF4EwSgu5Uez6vHqlL76C root@prometheus";
  karuppu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkRDFszaoQioHEQngCr0RAXmhYl+depj3dkZx/aSDQk root@karuppu";
  myUser = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1IVe3QU7hWvpOtNKsahORrB59ArqnX3jQ1xhL74YCE vks@tutamail.com";

  allHosts = [
    prometheus
    karuppu
  ];
in
{
  "surfshark-key.age".publicKeys = allHosts ++ [ myUser ];
  "borg.prometheus.age".publicKeys = allHosts ++ [ myUser ];
  "borg.borgbase.age".publicKeys = allHosts ++ [ myUser ];
}
