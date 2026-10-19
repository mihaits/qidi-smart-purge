# Smart purge for the QIDI Plus5 + QIDI Box

The stock start G-code of the QIDI Plus5 with a QIDI Box reloads the filament and purges about 200 mm at the start of every print, even when the same spool is already sitting in the nozzle from the print before.

These Klipper macros skip that when nothing has changed:

- **Same slot, same filament still loaded:** no reload and no long purge, only a short prime (25 mm).
- **Anything else** (another slot, a different spool in that slot, nothing loaded, box off): the stock full load and purge, unchanged.

The decision is printed to the console at the start of each print, for example:

```
Smart purge: slot1 already loaded (same filament), skipping purge
Smart purge: slot2 not loaded (nozzle has slot1), full purge
Smart purge: spool in slot1 changed since last print, full purge
```

## How it decides

QIDI's firmware keeps the box state in Klipper's saved variables. The macros only read them, and add one variable of their own (`smart_purge_sig`):

| Variable | Meaning |
|---|---|
| `value_tN` | which slot tool N uses (e.g. `slot1`) |
| `slot_sync` | which slot is in the nozzle (`slot-1` = none) |
| `slotN` | that slot's state: `2` = loaded into the nozzle |
| `filament_slotN`, `color_slotN`, `vendor_slotN` | the filament set for that slot on the printer screen |
| `smart_purge_sig` | slot + filament + colour + vendor at the last print (written by the macros) |

The purge is skipped only when the box is enabled, the tool's slot is the one in the nozzle and marked loaded, and the slot's filament, colour and vendor are the same as at the last print. Changing the filament or colour of that slot on the printer screen therefore forces a full purge.

## What's in here

| File | What |
|---|---|
| `smart_purge.cfg` | the macros: `SMART_PURGE_CHECK`, `SMART_FLUSH`, `SMART_PRIME` |
| `install.sh` | installs or removes `smart_purge.cfg` on the printer |
| `qidistudio/X-Plus 5 0.4 nozzle - Smart Purge.json` | a QIDI Studio printer profile that uses the macros |
| `smart_purge_patch.py` | rewrites an already-sliced `.gcode.3mf` to use the macros |

## Install

1. **On the printer** (SSH as `qidi`), copy this folder over and run:
   ```
   cd smart-purge && ./install.sh
   ```
   This copies `smart_purge.cfg` to `~/printer_data/config/klipper-macros-qd/`. QIDI's `printer.cfg` already includes every `.cfg` in that folder, so no QIDI file is edited. Klipper is restarted if the printer is idle.

2. **In QIDI Studio**, add the profile:
   - **File → Import → Import Configs**, and pick `qidistudio/X-Plus 5 0.4 nozzle - Smart Purge.json`. Or copy the file into `%APPDATA%\QIDIStudio\user\<your user id or "default">\machine\` and restart QIDI Studio.
   - In the **Prepare** tab, open the printer dropdown and choose **X-Plus 5 0.4 nozzle - Smart Purge** under *User presets*.

   The profile inherits QIDI's built-in "X-Plus 5 0.4 nozzle" profile and changes only the machine G-code:
   - **Start G-code:**
     - `SMART_PURGE_CHECK EXTRUDER=[initial_no_support_extruder]` before `BOX_PRINT_START`.
     - `EXTRUSION_AND_FLUSH` becomes `SMART_FLUSH`.
     - `G1 E200 F300` becomes `SMART_PRIME LEN=200 SHORT=25`.
   - **End G-code:** `UNLOAD_FILAMENT` is commented out, so the filament stays in the nozzle for the next print. Without this, every print ends unloaded and the next one always purges.

   For your own profile, make the same four edits to its machine G-code.

3. **Files you already sliced:** `python smart_purge_patch.py in.gcode.3mf out.gcode.3mf` writes a copy that uses the macros. It changes only the three start G-code lines and updates the file's MD5. The end G-code is left as it is.

## Remove

```
./install.sh uninstall
```

This deletes the `.cfg` and restarts Klipper. Then switch QIDI Studio back to the stock printer profile: a file sliced with the Smart Purge profile calls these macros and fails without them. The `smart_purge_sig` saved variable stays behind; it's harmless, and nothing else reads it.

A QIDI firmware update may replace the `klipper-macros-qd` folder. If the console says `Unknown command: "SMART_PURGE_CHECK"`, run `./install.sh` again.

## Notes

- **Changing slots with filament left loaded:** because the profile no longer unloads at the end, the next print on a *different* slot starts with the old filament still in the nozzle. `BOX_PRINT_START` is expected to cut and unload it before loading the new slot, as it does for mid-print colour changes. Watch the first print where you switch slots. If the old filament isn't unloaded, unload from the printer screen before switching.
- **Manual loads count:** loading a slot from the printer screen sets the same variables, so a print on that slot right after skips the purge.
- Tested on a QIDI Plus5 with one QIDI Box and QIDI Studio 2.7.

## License

MIT, see `LICENSE`.
