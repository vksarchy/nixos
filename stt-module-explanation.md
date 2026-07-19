# STT Module — Line-by-Line Breakdown

`modules/stt.nix` — a NixOS module that adds push-to-talk speech-to-text via
whisper.cpp with a toggle keybinding. Press once to record, press again to
transcribe and type at the cursor.

---

## Module header + imports

```nix
{ config, lib, pkgs, ... }:
```

Standard NixOS module function signature. `config` holds the final merged
configuration (all modules combined), `lib` is the nixpkgs library
(`lib.mkOption`, `lib.mkIf`, etc.), `pkgs` is the package set.

---

## Let bindings (computed before the module body)

```nix
let
  cfg = config.workstation.stt;
```

Shortcut — all our options live under `workstation.stt.*`, so this avoids
repeating the full path everywhere below.

---

### Model registry

```nix
  models = {
    tiny = { url = "..."; hash = "sha256-..."; };
    base = { url = "..."; hash = "sha256-..."; };
    small = { ... };
    medium = { ... };
  };
```

Each whisper.cpp model is a GGUF-format binary hosted on HuggingFace
(`ggerganov/whisper.cpp`). The `url` is the direct download, and `hash` is
the SRI-format SHA-256 hash that Nix uses to verify the download is correct
and hasn't been tampered with.

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| tiny  | 75MB | Fast  | Good for dictation |
| base  | 142MB | Moderate | Better |
| small | 466MB | Slow | High |
| medium | 1.5GB | Very slow | Best |

Only `tiny` and `base` have real hashes (prefetched with `nix-prefetch-url`).
`small` and `medium` have placeholder hashes — using them will fail with a
hash mismatch until you prefetch them.

---

### Model download

```nix
  modelFile = pkgs.fetchurl {
    name = "whisper-${cfg.model}.bin";
    url = models.${cfg.model}.url;
    hash = models.${cfg.model}.hash;
  };
```

`fetchurl` is a Nix built-in that downloads a file and stores it immutably in
`/nix/store/`. The `name` gives it a human-readable filename. The `hash` is
verified after download — if it doesn't match, the build fails (tamper-proof).
`${cfg.model}` is an interpolation: if the user sets `stt.model = "base"`,
this downloads the base model. The file ends up at a path like
`/nix/store/<hash>-whisper-base.bin`.

---

### The STT script

```nix
  sttScript = pkgs.writeShellScriptBin "stt-record" ''
```

`writeShellScriptBin` creates a derivation that produces an executable shell
script at `/nix/store/<hash>-bin-stt-record/bin/stt-record`. Nix automatically
places this on `PATH` when added to `environment.systemPackages`. The `''...''`
is a Nix multi-line string (two single quotes on each side). Inside it, `''${`
escapes a literal `${` so the shell script sees `$VAR` at runtime rather than
Nix trying to interpolate it at build time.

---

```bash
    PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/stt-pid"
    WAVFILE="${XDG_RUNTIME_DIR:-/tmp}/stt-recording.wav"
    MODEL="${modelFile}"
    THREADS=$(nproc)
```

- `PIDFILE` — tracks whether recording is in progress (file exists = recording).
  Uses `XDG_RUNTIME_DIR` (a tmpfs at `/run/user/1000/`) if available,
  falls back to `/tmp`.
- `WAVFILE` — temporary audio file. Same tmpfs location for speed (no disk I/O).
- `MODEL` — path to the whisper model in the Nix store (injected at build time).
- `THREADS` — all CPU cores, passed to whisper-cpp for faster transcription.

---

### Toggle logic: first press → start recording

```bash
    if [ -f "$PIDFILE" ]; then
      # second press — stop + transcribe
    else
      # first press — start recording
      ${pkgs.pipewire}/bin/pw-record "$WAVFILE" &
      echo $! > "$PIDFILE"
      ${pkgs.libnotify}/bin/notify-send "STT" "Recording... press Alt+T again to stop" -t 2000
    fi
```

`pw-record` is PipeWire's CLI audio recorder. It captures from the default
microphone and writes a WAV file. It runs in the background (`&`), and its
PID is saved to the PIDFILE. The user gets a desktop notification confirming
recording has started.

The `read`-from-terminal approach was deliberately avoided — that would steal
focus. This toggle approach lets the user keep their cursor in the target
window (browser, editor, chat).

---

### Toggle logic: second press → stop + process

```bash
      PID=$(cat "$PIDFILE")
      kill "$PID" 2>/dev/null || true
      wait "$PID" 2>/dev/null || true
      rm -f "$PIDFILE"
```

Reads the saved PID, sends SIGTERM to `pw-record`, waits for it to finish
writing the WAV file, then cleans up the PIDFILE.

---

### Silence gate (sox RMS check)

```bash
      RMS=$(${pkgs.sox}/bin/sox "$WAVFILE" -n stat 2>&1 | ${pkgs.gawk}/bin/awk '/RMS.*amplitude/ {print $3; exit}')
      if [ -z "${RMS:-}" ] || [ "$(echo "$RMS < 0.004" | ${pkgs.bc}/bin/bc -l)" = 1 ]; then
        rm -f "$WAVFILE"
        ${pkgs.libnotify}/bin/notify-send "STT" "No speech detected" -t 2000
        exit 0
      fi
```

**This is the key optimization for responsiveness.** Before running the
expensive whisper model, `sox stat` calculates the RMS (Root Mean Square)
amplitude of the audio — essentially how "loud" it is.

- RMS < 0.004: silence or near-silence. Skip whisper entirely, respond
  instantly with "No speech detected".
- RMS ≥ 0.004: actual audio. Proceed to transcription.

Why this matters: whisper.cpp takes 1-5 seconds even for the tiny model on
silence. `sox stat` takes milliseconds. The threshold 0.004 was chosen
empirically — it filters out room tone, fan noise, and accidental triggers
while passing real speech.

`bc -l` does floating-point comparison (bash can only do integers).

---

### Whisper transcription

```bash
      TEXT=$(${pkgs.whisper-cpp}/bin/whisper-cli \
        -m "$MODEL" \
        -f "$WAVFILE" \
        -l en \
        -t "$THREADS" \
        --no-timestamps \
        --no-speech-thold 0.5 \
        2>/dev/null) || true
      rm -f "$WAVFILE"
```

- `-m "$MODEL"` — path to the GGUF model file in the Nix store.
- `-f "$WAVFILE"` — input audio.
- `-l en` — language hint (English). Reduces hallucination in other languages.
- `-t "$THREADS"` — use all CPU cores for faster processing.
- `--no-timestamps` — output only the transcribed text, no `[00:01.234]` markers.
- `--no-speech-thold 0.5` — whisper.cpp's built-in speech probability threshold.
  If the model's confidence that any speech exists is below 0.5, it outputs
  nothing. This is a second guard after the sox check.
- `2>/dev/null` — suppress whisper's progress/status output.
- `|| true` — if whisper returns non-zero (empty audio, corrupted WAV),
  don't crash the script.

The WAV file is deleted immediately after processing — no disk clutter.

---

### Typing and clipboard

```bash
      if [ -n "${TEXT:-}" ]; then
        echo "$TEXT" | ${pkgs.wl-clipboard}/bin/wl-copy
        printf '%s' "$TEXT" | ${pkgs.wtype}/bin/wtype -
```

- `wl-copy` — copies the text to the Wayland clipboard (backup if typing fails).
- `wtype -` — types the text from stdin as if it came from a physical keyboard.
  The `-` flag reads from stdin. The text appears wherever the cursor is focused.

**Critical detail:** `printf '%s'` is used instead of `<<< "$TEXT"` (here-string).
Here-strings append a trailing newline, which `wtype` interprets as pressing Enter.
`printf` sends exactly the characters — no phantom Enter key.

---

### Notifications

```bash
        ${pkgs.libnotify}/bin/notify-send "STT" "${TEXT:0:80}" -t 3000
      else
        ${pkgs.libnotify}/bin/notify-send "STT" "No speech detected" -t 2000
      fi
```

`notify-send` pops up a desktop notification via D-Bus (picked up by the
notification daemon — e.g., dunst, mako, KDE's native notifier).

- Success: shows first 80 characters of the transcribed text for 3 seconds.
- Silence: shows "No speech detected" for 2 seconds.

---

## Module options

```nix
  options.workstation.stt = {
    enable = lib.mkEnableOption "push-to-talk speech-to-text (whisper.cpp)";
    model = lib.mkOption {
      type = lib.types.enum [ "tiny" "base" "small" "medium" ];
      default = "tiny";
      description = "Whisper model size...";
    };
  };
```

Two options:

- `workstation.stt.enable` — boolean. When `true`, the module activates.
  Standard NixOS module pattern.
- `workstation.stt.model` — enum of four model sizes. Default is `"tiny"`
  for speed. Users wanting better accuracy can set it to `"base"`.

---

## Module activation

```nix
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      whisper-cpp
      wtype
      libnotify
      sox
      gawk
      bc
      sttScript
    ];
  };
```

Everything inside `lib.mkIf cfg.enable` only takes effect when
`workstation.stt.enable = true`. The `with pkgs; [...]` block adds these
packages to the system-wide `PATH`:

| Package | Purpose |
|---------|---------|
| `whisper-cpp` | The transcription engine (whisper-cli binary) |
| `wtype` | Wayland key injection — types text at the cursor |
| `libnotify` | Desktop notifications (notify-send) |
| `sox` | Audio analysis — RMS energy check for silence detection |
| `gawk` | GNU awk — parses sox stat output |
| `bc` | Arbitrary precision calculator — floating-point comparison |
| `sttScript` | Our custom script (the derivation we built above) |

`pipewire` and `wl-clipboard` are NOT listed — they're assumed present on
any Wayland NixOS desktop (part of the standard desktop environment).

---

## How to use on a new machine

1. Add to the device's imports:
   ```nix
   imports = [
     ../../../modules/stt.nix
     # ...
   ];
   ```

2. Enable in the workstation block:
   ```nix
   workstation.stt.enable = true;
   # Optional: workstation.stt.model = "base";
   ```

3. Add a keybinding in your WM/DE config. For Niri:
   ```kdl
   binds {
     Alt+T { spawn "stt-record"; }
   }
   ```

4. Rebuild: `sudo nixos-rebuild switch --flake .#<hostname>`

---

## The full flow

```
Alt+T (first press)
  → pw-record starts in background
  → notification: "Recording..."
  [user speaks]
Alt+T (second press)
  → kill pw-record
  → sox stat: RMS check
    ├─ < 0.004  → instant "No speech detected"
    └─ ≥ 0.004  → whisper-cli --no-speech-thold 0.5
                   ├─ no text     → "No speech detected"
                   └─ has text    → wl-copy + wtype + notification
```
