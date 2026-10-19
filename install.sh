#!/bin/bash
# Smart purge for the QIDI Plus5 + QIDI Box. Run on the printer, from this folder.
#   ./install.sh            copy smart_purge.cfg into QIDI's macro folder and restart Klipper
#   ./install.sh uninstall  remove it again and restart Klipper
#   ./install.sh status
#
# QIDI's printer.cfg already includes klipper-macros-qd/*.cfg, so no QIDI file
# is edited: the install is one extra file, and uninstalling deletes it.
# Klipper is only restarted while the printer is idle; otherwise run
# FIRMWARE_RESTART yourself after the print.
cd "$(dirname "$0")"
DIR=$HOME/printer_data/config/klipper-macros-qd
FILE=$DIR/smart_purge.cfg
API=http://127.0.0.1:7125

restart() {
  state=$(curl -s "$API/printer/objects/query?print_stats=state" | grep -o '"state": *"[a-z]*"' | grep -o '[a-z]*"$' | tr -d '"')
  case "$state" in
    printing|paused) echo "the printer is $state: run FIRMWARE_RESTART after the print to apply this" ;;
    *) curl -s -X POST "$API/printer/firmware_restart" >/dev/null && echo "Klipper restarted" ;;
  esac
}

case "$1" in
  ""|install)
    grep -qs "^\[include klipper-macros-qd/\*\.cfg\]" "$HOME/printer_data/config/printer.cfg" ||
      { echo "printer.cfg doesn't include klipper-macros-qd/*.cfg: not a stock QIDI Plus5 config, nothing installed"; exit 1; }
    cp smart_purge.cfg "$FILE" && echo "installed $FILE"
    restart
    echo "Next: print with the slicer profile in qidistudio/ (see README.md)." ;;
  uninstall)
    rm -f "$FILE" && echo "removed $FILE"
    restart
    echo "Switch QIDI Studio back to the stock printer profile: files sliced with the Smart Purge profile need these macros." ;;
  status)
    if [ -f "$FILE" ]; then
      cmp -s smart_purge.cfg "$FILE" && echo "installed (same as this folder)" || echo "installed (differs from this folder)"
    else echo "not installed"; fi ;;
  *) sed -n 2,5p "$0" ;;
esac
