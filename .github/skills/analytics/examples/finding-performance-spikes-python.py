# tools/session_analysis.py
import re, statistics, pathlib

log = pathlib.Path("logs/session.log").read_text()
times = [float(m) for m in re.findall(r"frame_time=(\d+\.\d+)ms", log)]

if times:
    print(f"frames: {len(times)}")
    print(f"avg: {statistics.mean(times):.2f}ms")
    print(f"p95: {sorted(times)[int(len(times)*0.95)]:.2f}ms")
    print(f"max: {max(times):.2f}ms")
    spikes = [t for t in times if t > 33.3]   # > 2 frames at 60fps
    print(f"frame spikes >33ms: {len(spikes)}")
