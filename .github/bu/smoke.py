"""Smoke test run inside a freshly built image (see bu-build-images.yml).

Imports every installed distribution that ships a compiled extension, so an
arch-mismatched or missing native wheel fails here instead of at pod start.
Also checks the ELF machine of OpenResty's lua-cjson when present (registry).
"""

import importlib
import importlib.metadata as md
import os
import platform
import sys

ELF_MACHINE = {"x86_64": 0x3E, "aarch64": 0xB7}
CJSON = "/usr/local/lib/lua/5.1/cjson.so"


def elf_machine(path):
    with open(path, "rb") as f:
        head = f.read(20)
    assert head[:4] == b"\x7fELF", f"{path} is not an ELF file"
    return int.from_bytes(head[18:20], "little")


def main():
    machine = platform.machine()
    expect = os.environ.get("EXPECT_MACHINE")
    print(f"python {sys.version.split()[0]} machine={machine} expect={expect}")
    if expect and machine != expect:
        sys.exit(f"machine mismatch: {machine} != {expect}")

    ok, skipped, failed = [], [], []
    for dist in sorted(md.distributions(), key=lambda d: d.metadata["Name"].lower()):
        files = dist.files or []
        if not any(f.suffix == ".so" for f in files):
            continue
        name = dist.metadata["Name"]
        tops = (dist.read_text("top_level.txt") or "").split() or [name.replace("-", "_")]
        for top in tops:
            try:
                importlib.import_module(top)
                ok.append(f"{name}:{top}")
            except ModuleNotFoundError as e:
                # Stale or non-module top_level.txt entries, not a native problem.
                if e.name == top:
                    skipped.append(f"{name}:{top}")
                    continue
                failed.append(f"{name}:{top}: {e!r}")
            except Exception as e:  # noqa: BLE001 - report everything
                failed.append(f"{name}:{top}: {e!r}")

    print(f"compiled imports ok={len(ok)} skipped={len(skipped)} failed={len(failed)}")
    for line in ok:
        print("  ok  ", line)
    for line in skipped:
        print("  skip", line)
    for line in failed:
        print("  FAIL", line)

    if os.path.exists(CJSON):
        got = elf_machine(CJSON)
        want = ELF_MACHINE[machine]
        print(f"{CJSON}: e_machine=0x{got:02x} want=0x{want:02x}")
        if got != want:
            failed.append(f"{CJSON}: e_machine 0x{got:02x} != 0x{want:02x}")

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
