# Smart purge for the QIDI Plus5 + QIDI Box

At the start of every print, the QIDI Plus5 reloads the filament and purges about 200 mm, even when the same spool is already in the nozzle. These Klipper macros skip that when nothing has changed:

- **Same slot, same filament still loaded:** no reload, just a 25 mm prime.
- **Anything else** (another slot, a different spool, nothing loaded): the normal full purge.

Each print logs its decision to the console, e.g. `Smart purge: slot1 already loaded (same filament), skipping purge`.

## Install

1. **Printer** (SSH as `qidi`): copy this folder over and run `./install.sh`.
   It copies `smart_purge.cfg` into QIDI's `klipper-macros-qd` folder, which is already included, so no QIDI file is edited. It also restarts Klipper if the printer is idle.
2. **QIDI Studio:** use **File → Import → Import Configs**, pick `qidistudio/X-Plus 5 0.4 nozzle - Smart Purge.json`, and select that printer profile.
   The profile is QIDI's own with four G-code edits:
   - `SMART_PURGE_CHECK` before `BOX_PRINT_START`.
   - `SMART_FLUSH` instead of `EXTRUSION_AND_FLUSH`.
   - `SMART_PRIME` instead of `G1 E200 F300`.
   - No `UNLOAD_FILAMENT` at the end, so the filament stays loaded for the next print.

Already-sliced files: `python smart_purge_patch.py in.gcode.3mf out.gcode.3mf`.

## After a QIDI firmware update

The update deletes the macros. Run `./install.sh` again, or prints sliced with this profile stop with "Unknown command SMART_PURGE_CHECK".

## Remove

Run `./install.sh uninstall`, then switch QIDI Studio back to the stock printer profile.

## Tested with

| | Version |
|---|---|
| Printer firmware | 01.01.01.07, 01.01.02.01 |
| MCU / toolhead / box firmware | 02.01.01.12 / 02.02.01.08 / 02.03.01.21 |
| QIDI Studio | 2.7.2.60 |

These versions were tested with one original (USB) QIDI Box.

## How it decides

It skips the purge only when all of these hold:
- the box is enabled;
- the tool's slot (`value_tN`) is the one in the nozzle (`slot_sync`, with `slotN` = 2);
- the slot's filament, colour and vendor match the last print.

The macros store a hash of those values in the saved variable `smart_purge_sig`.

## License

MIT
