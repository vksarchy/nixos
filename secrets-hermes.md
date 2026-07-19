
─  ⚕ Hermes  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

     AGENIX MASTERCLASS — What You Just Built
     THE 3 PIECES (every secret needs all 3)

     PIECE 1                    PIECE 2                    PIECE 3
     secrets/secrets.nix        secrets/*.age             device config
     ───────────────            ─────────────             ─────────────
     WHO can read               WHAT the secret IS        WHERE it lands

     "hello-world.age"          Encrypted with             age.secrets.hello-world = {
       .publicKeys =              prometheus + sid            file = .../hello-world.age;
         [prometheus sid erebos]   + erebos                   owner = "sid";
                                                               mode = "0400";
          ↓                        ↓                        }
          └── agenix reads this ──→└── to encrypt/decrypt ──→     ↓
                                                                /run/agenix/hello-world
                                                                (tmpfs, RAM only, 0400)

     THE COMMANDS

     bash
     CREATE a new secret (opens $EDITOR — type content, save, exit)
     cd ~/nixos/secrets
     agenix -e mysercet.age
     EDIT an existing secret
     agenix -e mysercet.age        # re-opens $EDITOR with current content
     RE-KEY all secrets (after adding/removing a machine key)
     agenix -r                     # decrypts + re-encrypts with current keys
     MANUAL decrypt (for testing)
     nix-shell -p age --command "age -d -i ~/.ssh/id_ed25519 secrets/mysercet.age"

     KEY RULES

     1. Name matches: age.secrets."NAME" → secret file is at /run/agenix/NAME
     2. .age file = git: Every .age file MUST be git added (flake rule)
     3. Secure by default: Nobody except owner can read it (mode 0400)
     4. RAM only: /run/ is tmpfs — plain text never touches disk
     5. Systemd after: Services using secrets need after = [ "agenix.service" ]
     6. Reference in nix: config.age.secrets.NAME.path → resolves to /run/agenix/NAME
     TO PRACTICE ON YOUR OWN

     bash
     1. Create a secret
     cd ~/nixos/secrets
     agenix -e my-api-key.age
     Type: sk-abc123def456
     2. Declare who can read it in secrets.nix
     "my-api-key.age".publicKeys = [ prometheus sid ];
     3. Wire it into your device config
     age.secrets.my-api-key = {
     file = ../../../secrets/my-api-key.age;
     owner = "sid";
     };
     4. git add, rebuild
     git add secrets/my-api-key.age secrets/secrets.nix devices/...
     sudo nixos-rebuild switch --flake .#karuppu
     5. Verify
     cat /run/agenix/my-api-key

     TO CLEAN UP THE DEMO

     When you're done learning, just:
     1. Remove the age.secrets.hello-world and systemd.services.hello-world-secret blocks from devices/desktop/karuppu/default.nix
     2. Remove "hello-world.age" line from secrets/secrets.nix
     3. rm secrets/hello-world.age
     4. Rebuild

     The secret is currently live at /run/agenix/hello-world — readable only by you (-r-------- sid users).

====
-----


    Already done in the previous session! Here's the recap:

     What we have:

     /home/sid/eta.tar.gz.age    ← 4.9MB encrypted (safe, can delete original folder)
     /home/sid/Downloads/eta/    ← original (still there, you can delete it)

     Why age not agenix: Agenix is for text secrets (passwords, tokens, env files) — you edit them in $EDITOR. For binary files/folders
     (PDFs, JPEGs, ZIPs), you use age directly.

     TO DECRYPT/UNLOCK:
     bash
     nix-shell -p age --command "age -d -i ~/.ssh/id_ed25519 -o eta.tar.gz eta.tar.gz.age"
     tar xzf eta.tar.gz

     TO RE-LOCK (encrypt):
     bash
     tar czf eta.tar.gz eta/
     nix-shell -p age --command "age -e -r 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILVpY3ih0mBO0l4UrKFOLaiHzLsqcDX1otrNOu6HpbUw' -o
     eta.tar.gz.age eta.tar.gz"
     rm eta.tar.gz

     The encryption is tied to your ~/.ssh/id_ed25519 SSH key — same key now listed as sid in secrets.nix.

     If you want it as an agenix-style NixOS secret (auto-decrypted at boot to /run/agenix/), that only works for text content. You'd need
     to base64-encode the tarball and store that as a text secret — messy and not recommended. age directly is the right tool here.

     Want me to delete the original eta/ folder now that it's safely encrypted?

