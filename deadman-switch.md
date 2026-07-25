# Deadman switch: 3 wrong passwords → (threaten /) erase

> Saved design notes — **not implemented**. Revisit later.

**Status:** Design only.  
**Scope:** Every PAM auth surface (noctalia lock, ly greeter, TTY `login`, `sudo`/`su`, SSH if enabled).  
**Host:** `prometheus` (ThinkPad laptop).

---

## Context

You want a “movie villain” security feature: after **3 wrong password attempts**, the machine should make it clear that everything will be destroyed — and (if armed for real) actually wipe.

### What you have today

| Fact | Implication |
|------|-------------|
| Root is **plain ext4** on `nvme0n1p2` (no LUKS) | Instant crypto-erase is **not** available. True “data is gone” needs FDE migration or NVMe secure-erase. |
| Session lock = **Noctalia** via PAM (`pam_authenticate`) | Failures go through PAM → we can hook them. |
| Greeter = **ly** (`/etc/pam.d/ly`) | Same story. |
| TTY/console = `/etc/pam.d/login` | Same story. |
| No `pam_faillock` / tally today | No fail counter yet; must add one. |
| Backups = BorgBase for selected paths | Soft-kill is recoverable; hard-kill of unbacked data is not. |

### Threat model (honest)

| Attacker | Deadman helps? |
|----------|----------------|
| Casual thief typing passwords on lock screen | Yes — scare / soft-kill / hard-kill all apply |
| Thief who reboots to live USB **and you have no FDE** | **No** — they read the disk cold |
| Thief who reboots and you have **LUKS** | Hard-kill of LUKS header is meaningful if done before they unlock |
| You fat-finger password 3× at 2am | You nuke yourself — design for this |

**Bottom line:** Without full-disk encryption, “erase the laptop” is either slow disk thrash or theater. With LUKS, “erase” is a 1-second header kill and is actually useful.

---

## Recommended architecture (when you implement)

One shared **deadman** subsystem, armed for **all PAM services**, with three severity modes (pick one at enable time).

```
                    ┌─────────────────────────────┐
  wrong password ──►│  PAM stack (all services)   │
                    │  pam_unix → fail branch     │
                    └─────────────┬───────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────────┐
                    │  /run/wrappers/bin/deadman  │  (setuid-root or CAP)
                    │  - bump counter in /var/lib │
                    │  - reset on success path    │
                    │  - emit warning / wipe      │
                    └─────────────┬───────────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              ▼                   ▼                   ▼
         attempt 1            attempt 2            attempt 3
         soft warn            dramatic warn        wipe path
```

### 1. Fail counting (PAM)

Use the classic **skip-on-success** pattern so the fail handler only runs after a bad password:

```pam
# Conceptual stack fragment for EVERY relevant service
auth  [success=1 default=ignore]  pam_unix.so try_first_pass nullok
auth  requisite                   pam_exec.so quiet expose_authtok /run/wrappers/bin/deadman fail
auth  optional                    pam_permit.so
# … existing sufficient/required lines adjusted carefully
```

Success path (separate line, after unix succeeds):

```pam
auth  optional  pam_exec.so quiet /run/wrappers/bin/deadman success
```

Or use **`pam_faillock`** for counting + lockout, and have `deadman` read the tally:

```bash
faillock --user sid   # inspect
```

**Services to wire (your “everything” choice):**

| Service file | Surface |
|--------------|---------|
| `ly` | Display manager greeter |
| custom `noctalia` (or whatever service name noctalia uses — verify with `strace -e openat` / docs; often `login` or hardcoded) | Session lock |
| `login` | TTY / getty |
| `sshd` | SSH (if enabled) |
| `sudo` / `su` / `polkit-1` | Escalation (aggressive — see risks) |
| `systemd-user` / unlock paths | Usually leave alone |

**NixOS knobs (when implementing):**

- `security.pam.services.<name>.text` or structured `rules`
- Or a small module that injects the same fragment into a list of services
- Prefer **one** NixOS module: `modules/deadman.nix` with `enable`, `mode`, `maxAttempts`, `targets`

### 2. Dramatic warning (the fun part)

Counter state: `/var/lib/deadman/state` (attempts, last fail time, armed flag).

| Attempts | UX |
|----------|----|
| **1** | Lockscreen still shows normal “invalid password”. Optional: brief red flash via `brightnessctl`, short glitch sound. |
| **2** | **Full drama:** TTS (`espeak-ng` / `piper`): *“Warning. One more incorrect password will permanently erase all data on this system.”* Flash screen, optional fullscreen red overlay if Wayland allows, write banner to all `/dev/tty[1-6]` via `wall` / `openvt`. |
| **3** | Final 10–15s countdown (TTS + tty banner): *“Purge sequence engaged. Enter correct password to abort.”* Then wipe path. |

**Where the UI can actually appear:**

| Context | What works |
|---------|------------|
| Noctalia lock | TTS + backlight flash; hard to inject custom QML without forking noctalia |
| TTY login | Full ASCII-art blood-red banners (`wall`, write to active tty) — best theater |
| ly greeter | Limited; TTS + console banner if switchable |
| After wipe starts | Fullscreen progress on TTY (`chvt 1` then `fbterm` / plain printf) |

**Overlay idea (optional later):** small `layer-shell` binary (`deadman-overlay`) run as the logged-in user via `systemd --user` path unit watching `/run/deadman/attempts` — shows “ATTEMPT 2/3 — ONE MORE WIPES EVERYTHING” over the lock. Needs the user session still alive (works for noctalia lock, not for greeter/TTY pre-login).

### 3. Wipe paths (mode switch)

Config enum:

```nix
deadman.mode = "theater" | "soft" | "hard";
deadman.maxAttempts = 3;  # fun default; recommend 5–10 if real
deadman.countdownSeconds = 15;
deadman.resetOnSuccess = true;
```

#### Mode A — `theater` (safest fun)

- Counter + drama only.
- On 3: fake progress bar, reboot into a “SYSTEM PURGED” Plymouth/ly message, counter resets after reboot (or after success).
- Zero data loss.

#### Mode B — `soft`

On confirmed strike 3 (after countdown, no correct password):

1. `sync`
2. Shred/delete high-value paths: `/home/sid`, `/var/lib`, age keys, SSH keys, browser profiles, Borg cache (define explicit list)
3. `shred -n 1` or `rm -rf` then `sync`
4. `systemctl poweroff --force`

Recoverable via reinstall + Borg restore. Disk forensics may still recover unencrypted data.

#### Mode C — `hard` (only worth it with FDE)

**Prerequisite (big project):** reinstall or migrate `prometheus` to **LUKS** on root (and ideally swap).

Then wipe = **seconds**, not hours:

```bash
cryptsetup luksErase /dev/disk/by-uuid/<root-luks>   # destroys keyslots
wipefs -a /dev/disk/by-uuid/<root-luks>              # optional header scrub
# or: dd if=/dev/urandom of=/dev/nvme0n1p2 bs=1M count=16
systemctl poweroff --force
```

Ciphertext remains but is unreadable forever (without header backup).

**Alternative hard path without reinstall:** NVMe sanitize/secure-erase:

```bash
nvme format /dev/nvme0n1 --ses=1   # vendor/firmware dependent; verify support
```

This wipes the **whole drive** including `/boot` — machine won’t boot until reinstall. Must test on spare media first; some drives ignore SES.

### 4. Success path

On any successful auth for the watched user:

- Reset counter to 0
- Cancel pending countdown (`systemd-run` unit or PID file)
- Dismiss overlay / stop TTS

### 5. Safety interlocks (mandatory if mode ≠ theater)

| Interlock | Why |
|-----------|-----|
| `deadman.mode = "theater"` default | Don’t ship live nukes by accident |
| Arming flag `/etc/deadman.armed` or `deadman.armed = true` | Explicit opt-in |
| Kill switch `/etc/deadman.disarmed` present → no-op | Rescue from live USB if you still can |
| Countdown with abort on correct password | Fat-finger protection |
| Exclude fingerprint-only fails from tally (or count separately) | fprintd spam |
| Don’t count empty password submits if noctalia allows them | Accidental Enter |
| Log everything to journal with `deadman:` prefix | Forensics / debugging |
| Higher threshold for `sudo`/`su` (e.g. 10) or exclude them | Daily work won’t arm nuclear option |
| Header backup stored **offline** if LUKS hard mode | Your own escape hatch |

**Strong recommendation:** even if UX says “3”, implement `maxAttempts` and set **5–10** for any real mode. Three is comedy-tight.

---

## Coverage map: “everything including TTY”

```
┌──────────────┬─────────────────┬────────────────────────────┐
│ Surface      │ PAM service     │ Notes                      │
├──────────────┼─────────────────┼────────────────────────────┤
│ Noctalia     │ (verify name)   │ Session lock after lid     │
│ ly greeter   │ ly              │ Pre-session                │
│ TTY1–N       │ login           │ Ctrl+Alt+Fn — full banners │
│ SSH          │ sshd            │ Only if openssh enabled    │
│ sudo         │ sudo            │ Optional; high false risk  │
│ su           │ su              │ Optional                   │
│ polkit auth  │ polkit-1        │ Optional; GUI prompts      │
└──────────────┴─────────────────┴────────────────────────────┘
```

**TTY is the best place for drama** — you control the whole framebuffer text console. Greeter/lock are constrained by compositor UI.

**Catch:** A thief who never types a password and boots a live USB **bypasses all of this** unless the disk is encrypted. Deadman protects against *online password grinding*, not offline disk imaging.

---

## Implementation sketch (future PR plan — not doing now)

When you want to build it:

1. **`modules/deadman.nix`**
   - options: `enable`, `mode`, `maxAttempts`, `countdownSeconds`, `user`, `services[]`
   - package `pkgs.writeShellApplication` + optional small overlay binary
   - PAM injection for listed services
   - state dir + systemd units for countdown cancel

2. **`devices/laptop/prometheus/default.nix`**
   - `workstation.deadman.enable = true; mode = "theater";` first

3. **Verify noctalia PAM service name**
   - Confirm which `/etc/pam.d/*` noctalia opens (may need custom file)

4. **Dry-run test plan**
   - Mode theater on a spare user or VM first
   - Force 1/2/3 fails on TTY, lock, ly
   - Confirm success resets counter
   - Confirm kill-switch file disables wipe

5. **Optional phase 2: LUKS migration** (separate design)
   - Only then enable `mode = "hard"`

---

## Critical files (when implementing)

| Path | Role |
|------|------|
| `modules/deadman.nix` (new) | Module + scripts + PAM |
| `devices/laptop/prometheus/default.nix` | Enable on laptop only |
| `/etc/pam.d/{ly,login,sshd,sudo,...}` | Generated by NixOS PAM |
| Noctalia PAM service (TBD) | Must match real `pam_start` name |
| Not touched for design-only: `home/niri.nix`, swayidle | Orthogonal |

**Reuse:**

- Existing `security.pam` NixOS options
- `pkgs.espeak-ng` / `brightnessctl` for drama
- Journald for audit trail
- Optional: existing Borg backups for soft-mode recovery story

---

## Verification (when implemented)

1. **Theater**
   - Wrong password ×1 on lock → mild effect
   - ×2 → TTS + tty banner with “ONE MORE…”
   - ×3 → fake purge + reboot, disk intact
   - Correct password anytime → counter 0, countdown cancelled

2. **Cross-surface**
   - Same counter shared: 1 fail on TTY + 1 on lock + 1 on ly = purge (if that’s desired)
   - Or per-service counters (usually **shared** is scarier and simpler)

3. **TTY focus**
   - Switch to TTY2, fail thrice, see full dramatic sequence

4. **Disarm**
   - Touch `/etc/deadman.disarmed`, fail thrice → no wipe

5. **Hard mode (only after LUKS)**
   - VM with disposable LUKS volume; confirm `luksErase` makes volume unopenable; restore from header backup

---

## Decision summary

| Question | Answer (from you) |
|----------|-------------------|
| Implement now? | **No** — design doc only |
| Surfaces | **Everything** (lock, greeter, TTY, etc.) |
| Reality check | No FDE today → hard erase needs LUKS/NVMe work first |
| Fun path | Theater mode is the right first product |
| Serious path | LUKS migrate → `luksErase` on strike-out |

---

## Recommendation

Ship nothing destructive until you want it. If you build later:

1. Start with **`mode = "theater"`** + shared counter + TTS/TTY drama (max fun, zero regret).
2. Optionally add **soft** with explicit arming + countdown.
3. Only after **LUKS** (or proven NVMe sanitize), enable **hard**.

When you say go, implement `modules/deadman.nix` theater-first on `prometheus` only.
