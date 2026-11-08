"""Run native verification and capture unedited screenshots at visible checkpoints."""
import pathlib
import re
import subprocess
import sys

if len(sys.argv) != 2:
    raise SystemExit("Usage: python3 tool/capture_simulator.py <dedicated-simulator-id>")
output = pathlib.Path("docs/screenshots")
output.mkdir(parents=True, exist_ok=True)
process = subprocess.Popen(["flutter", "test", "integration_test/studio_test.dart", "-d", sys.argv[1], "--dart-define=CAPTURE_SCREENSHOTS=true"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
assert process.stdout is not None
try:
    for line in process.stdout:
        print(line, end="", flush=True)
        match = re.search(r"HUECRAFT_SCREENSHOT:([a-z-]+)", line)
        if match:
            name = match.group(1)
            container = subprocess.check_output(["xcrun", "simctl", "get_app_container", sys.argv[1], "com.owaismunawar.huecraft", "data"], text=True).strip()
            ready = list(pathlib.Path(container).rglob(f"huecraft-capture-{name}.ready"))
            if len(ready) != 1:
                raise RuntimeError("Expected one screenshot handshake file")
            subprocess.run(["xcrun", "simctl", "io", sys.argv[1], "screenshot", str(output / f"{name}.png")], check=True)
            pathlib.Path(str(ready[0]) + ".ack").touch()
    raise SystemExit(process.wait())
finally:
    if process.poll() is None:
        process.terminate()
