# Baut lib/levels.dart aus den Ausgaben von tool/gen.dart (ein Gebiets-String pro Zeile).
import sys, glob, os
out_dir = sys.argv[1]
parts = []
for f in sorted(glob.glob(os.path.join(out_dir, "*.txt")), key=lambda p: int(os.path.basename(p)[:-4])):
    n = int(os.path.basename(f)[:-4])
    lines = [l.strip() for l in open(f) if l.strip()]
    parts.append(f"  {n}: [\n" + "".join(f"    '{l}',\n" for l in lines) + "  ],\n")
open("lib/levels.dart", "w", encoding="utf-8").write(
    "// Generiert von tool/gen.dart + tool/assemble.py. Nicht von Hand ändern.\n"
    "const levels = <int, List<String>>{\n" + "".join(parts) + "};\n")
print({os.path.basename(f): sum(1 for _ in open(f)) for f in glob.glob(os.path.join(out_dir, "*.txt"))})
