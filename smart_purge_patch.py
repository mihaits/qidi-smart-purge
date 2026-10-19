#!/usr/bin/env python3
"""Make a copy of a QIDI .gcode.3mf whose start G-code uses the smart purge.
Usage: smart_purge_patch.py <in.gcode.3mf> <out.gcode.3mf>
Only executable lines are changed (comment lines holding the slicer config are left alone)."""
import sys, zipfile, hashlib, re

src, dst = sys.argv[1], sys.argv[2]
zin = zipfile.ZipFile(src)
name = next(n for n in zin.namelist() if n.endswith(".gcode"))
lines = zin.read(name).decode("utf-8").split("\n")

out, done = [], {"check": 0, "flush": 0, "prime": 0}
for l in lines:
    s = l.strip()
    m = re.match(r"BOX_PRINT_START EXTRUDER=(\d+)", s)
    if m and not done["check"]:
        out.append("SMART_PURGE_CHECK EXTRUDER=%s" % m.group(1)); done["check"] = 1
    elif s.startswith("EXTRUSION_AND_FLUSH ") and not done["flush"]:
        l = s.replace("EXTRUSION_AND_FLUSH", "SMART_FLUSH", 1); done["flush"] = 1
    elif s == "G1 E200 F300" and not done["prime"]:
        l = "SMART_PRIME LEN=200 SHORT=25"; done["prime"] = 1
    out.append(l)
if not all(done.values()):
    sys.exit("pattern not found: %s" % done)
data = "\n".join(out).encode("utf-8")

with zipfile.ZipFile(dst, "w") as zout:
    for i in zin.infolist():
        if i.filename == name:
            b = data
        elif i.filename == name + ".md5":
            b = hashlib.md5(data).hexdigest().upper().encode() if zin.read(i).decode().isupper() \
                else hashlib.md5(data).hexdigest().encode()
        else:
            b = zin.read(i)
        zout.writestr(i, b, compress_type=i.compress_type)
print("patched", done)
