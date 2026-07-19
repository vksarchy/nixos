

     Line by line:

     Lines 1-7: Module function signature

     nix
     { config, lib, pkgs, inputs, ... }:

     Every NixOS module is a function that receives the module system's standard
     arguments. The ... means "and any other arguments I don't explicitly name."
     The ones used in this module:
     - config — the final merged configuration (all modules combined). Used to
     read config.workstation.ssh to check if ssh is enabled.
     - lib — Nixpkgs standard library (lib.mkEnableOption, lib.mkIf, etc.)
     - pkgs — the package set (not actually used in this module, but available)
     - inputs — flake inputs (also unused here, but passed through)

     Lines 8-10: Local binding

     nix
     let
       cfg = config.workstation.ssh;
     in

     A let ... in block creates a local alias. Instead of writing
     config.workstation.ssh.enable repeatedly, we bind cfg to that path. Pure
     convenience. If this module were longer and referenced the SSH config in
     multiple places, cfg.enable is shorter than config.workstation.ssh.enable.

     Line 12: Option declaration

     nix
     options.workstation.ssh.enable = lib.mkEnableOption "Default SSH
     configuration";

     This creates a boolean option at path workstation.ssh.enable.
     lib.mkEnableOption does three things:
     1. Creates the option with type types.bool
     2. Defaults to false (off by default — safe default)
     3. Generates the description: "Whether to enable Default SSH
     configuration."

     So in your device config (prometheus/default.nix), setting
     workstation.ssh.enable = true flips this to on. Without it, SSH is
     disabled. This is a common pattern in your config (you have the same
     pattern for nixvim, yazi, kanata, niri, etc.).

     Line 13: Conditional config activation

     nix
     config = lib.mkIf cfg.enable {

     Everything inside this block only takes effect when cfg.enable is true.
     lib.mkIf is the standard way to write conditional NixOS config. If
     workstation.ssh.enable is false (or not set), everything inside { ... } is
     completely ignored. This is why sshd was inactive on prometheus —
     cfg.enable was false (the default), so lines 14-31 were never applied.

     Lines 14-16: Enable OpenSSH server

     nix
     services.openssh = {
       enable = true;
       ports = [ 22 ];

     - services.openssh.enable = true — This tells NixOS to run the OpenSSH
     daemon (sshd). NixOS generates the systemd service unit sshd.service,
     writes /etc/ssh/sshd_config from the settings below, and starts it at boot.
     - ports = [ 22 ] — Listen on port 22 (the standard SSH port). Changing this
     to e.g. [ 2222 ] would listen on 2222 instead (some people do this to avoid
     automated scanners).

     Lines 17-22: SSH daemon security settings

     nix
     settings = {
       PasswordAuthentication = false;
       KbdInteractiveAuthentication = false;
       PermitRootLogin = "no";
       AllowUsers = [ "sid" ];
     };

     These are injected directly into /etc/ssh/sshd_config by NixOS:

     - PasswordAuthentication = false — Disables password login entirely. No one
     can SSH in by typing a password. This is critical security: passwords can
     be brute-forced or leaked; key-based auth is cryptographically stronger.
     With this off, only SSH keys work.

     - KbdInteractiveAuthentication = false — Disables keyboard-interactive auth
     (a more complex challenge-response mechanism, sometimes used for 2FA or
     PAM-based auth). Also off. Combined with the above, the only way in is a
     valid SSH key.

     - PermitRootLogin = "no" — Blocks direct root SSH login. Even if someone
     had root's SSH key, they can't SSH as root. You must SSH as sid first, then
     sudo -i or sudo su to become root. This creates an audit trail — all
     privileged actions are logged under the user who escalated.

     - AllowUsers = [ "sid" ] — Whitelist: only the user sid is allowed to SSH
     in. Any other user (even if they exist and have authorized keys) is denied
     at the SSH protocol level before authentication even starts. Defense in
     depth — even if a stray user account exists, it can't be used for remote
     access.

     Lines 24-29: Authorized keys for user sid

     nix
     users.users."sid".openssh.authorizedKeys.keys = [
       "sk-ssh-ed25519@openssh.com AAA... yubikey1"
       "sk-ssh-ed25519@openssh.com AAA... yubikey 2 thinkpad"
       "sk-ssh-ed25519@openssh.com AAA... yubikey3 mobile"
       "sk-ssh-ed25519@openssh.com AAA... yubikey4 backup"
     ];

     (Note: your output masked the key type prefix as , but these are
     sk-ssh-ed25519@openssh.com — FIDO2 security keys.)

     Each line is a public key that can authenticate as sid. The key type
     sk-ssh-ed25519 means these are hardware-backed FIDO2 keys generated on
     YubiKeys. Unlike regular SSH keys (which are just files on disk), FIDO2
     keys require physical touch on the YubiKey to sign the auth challenge.
     Benefits:
     - The private key never leaves the YubiKey — it can't be exfiltrated by
     malware
     - Physical touch required per authentication (anti-bot, anti-remote-attack)
     - You can take the YubiKey to any machine and SSH without copying key files

     The comments at the end (yubikey1, yubikey 2 thinkpad, yubikey3 mobile,
     yubikey4 backup) are just human-readable labels. They appear in
     ~/.ssh/authorized_keys as comments so you can identify which key is which
     when auditing.

     NixOS writes these into /home/sid/.ssh/authorized_keys and ensures correct
     permissions (700 on .ssh, 600 on the file).

     Line 30: Firewall hole

     nix
     networking.firewall.allowedTCPPorts = [ 22 ];

     Opens port 22 in the NixOS firewall. Without this, even if sshd is running
     and bound to port 22, the kernel firewall drops the packets before they
     reach sshd. NixOS firewall is enabled by default and blocks everything
     except what's explicitly allowed. Adding 22 to allowedTCPPorts tells
     iptables/nftables to accept inbound TCP on port 22 from any source.

     Summary of the full flow when someone SSHes in:*

     1. Firewall passes TCP port 22
     2. sshd receives connection
     3. sshd checks AllowUsers — is the username sid? If not, reject immediately
     4. sshd checks PermitRootLogin — if root, reject
     5. sshd checks PasswordAuthentication and KbdInteractiveAuthentication —
     both false, so password auth is skipped
     6. sshd checks ~/.ssh/authorized_keys — does the offered public key match
     one of the 4 YubiKey keys?
     7. If yes: FIDO2 challenge-response handshake happens, user touches
     YubiKey, session opens
     8. If no: connection rejected (no password fallback available)

     The only weak point is if someone physically steals a YubiKey AND knows the
     PIN (FIDO2 resident keys require a PIN to unlock, set during key
     generation).
