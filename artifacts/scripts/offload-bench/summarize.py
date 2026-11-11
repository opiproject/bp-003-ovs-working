#!/usr/bin/env python3
"""~/bench/summarize.py RUN_DIR [WARM] — one line per run, then median and range per mode."""
import json, sys, re, glob, os, statistics as st

RUN = sys.argv[1]; WARM = float(sys.argv[2]) if len(sys.argv) > 2 else 5.0
DROPISH = re.compile(r"drop|discard|err|miss|overflow|prune|collapse", re.I); BENIGN = re.compile(r"pp_recycle|Coalesce", re.I)

def mpstat(fn):
    """Per-CPU 'Average:' rows of mpstat -P ALL -> {cpu: {column: value}}."""
    hdr, out = None, {}
    for line in open(fn, errors="ignore"):
        f = line.split()
        if len(f) > 3 and f[0] == "Average:" and f[1] == "CPU": hdr = f
        elif hdr and len(f) == len(hdr) and f[0] == "Average:":
            out[f[1]] = dict(zip(hdr[2:], map(float, f[2:])))
    return out

def cpu_view(fn):
    """Total cores busy, the busiest single core, and that core's softirq share."""
    m = mpstat(fn); cores = [k for k in m if k != "all"]
    if not cores or "all" not in m: return None
    hot = max(cores, key=lambda c: 100 - m[c]["%idle"])
    return {"cores_busy": round((100 - m["all"]["%idle"]) * len(cores) / 100, 2),
            "hot_core": hot, "hot_busy": round(100 - m[hot]["%idle"], 1),
            "hot_soft": m[hot]["%soft"], "soft_all": m["all"]["%soft"]}

def vhost_cores(fn):
    """Sum of %CPU of host vhost threads from pidstat -t, in cores."""
    hdr, tot = None, 0.0
    for line in open(fn, errors="ignore"):
        f = line.split()
        if len(f) > 3 and f[0] == "Average:" and "%CPU" in f: hdr = f
        elif hdr and len(f) == len(hdr) and f[0] == "Average:" and "vhost" in f[-1]:
            tot += float(f[hdr.index("%CPU")])
    return round(tot / 100, 2)

def counters(fn):
    """'== section' headers, then 'name: value' or 'name value' lines -> {section/name: value}."""
    sec, c = "", {}
    for line in open(fn, errors="ignore"):
        if line.startswith("== "): sec = line[3:].strip(); continue
        m = re.match(r"\s*([A-Za-z][\w\[\].-]*):?\s+(\d+)\b", line)
        if m: c[f"{sec}/{m.group(1)}"] = int(m.group(2))
    return c

def drops(d):
    """Drop/error counters that went up during the run, labelled by hop."""
    out = []
    for hop in ("vm1", "vm2", "host", "arm"):
        b, a = os.path.join(d, f"{hop}_before.txt"), os.path.join(d, f"{hop}_after.txt")
        if not (os.path.exists(b) and os.path.exists(a)): continue
        cb, ca = counters(b), counters(a)
        for k, v in ca.items():
            dv = v - cb.get(k, 0)
            if dv > 0 and DROPISH.search(k) and not BENIGN.search(k): out.append(f"{hop}:{k}+{dv}")
    return out

rows = []
for d in sorted(glob.glob(os.path.join(RUN, "r*_*"))):
    name = os.path.basename(d); r = {"run": name, "mode": name.split("_", 1)[1]}
    try:
        j = json.load(open(os.path.join(d, "iperf.json"))); e = j["end"]
        r["gbps_sent"] = round(e["sum_sent"]["bits_per_second"] / 1e9, 2)
        r["retx"] = e["sum_sent"].get("retransmits")
        steady = [i["sum"]["bits_per_second"] / 1e9 for i in j["intervals"] if i["sum"]["start"] >= WARM]
        r["gbps_steady"] = round(st.mean(steady), 2)
        r["cv_pct"] = round(100 * st.pstdev(steady) / st.mean(steady), 1)
    except Exception as ex:
        r["error"] = f"iperf: {ex}"
    for who in ("host", "vm1", "vm2", "arm"):
        fn = os.path.join(d, f"{who}_mpstat.txt")
        if os.path.exists(fn): r[who] = cpu_view(fn)
    fn = os.path.join(d, "host_pidstat.txt")
    if os.path.exists(fn): r["vhost_cores"] = vhost_cores(fn)
    fn = os.path.join(d, "flows_mid.txt")
    if os.path.exists(fn):
        t = open(fn).read(); fl = [l for l in t.splitlines() if l.startswith("ufid:")]
        r["flows_offloaded"] = f"{t.count('offloaded:yes')}/{len(fl)}"
        r["dp"] = ",".join(sorted(set(re.findall(r"dp:(\w+)", t))))
    r["drops"] = drops(d)
    rows.append(r)

for r in rows: print(json.dumps(r))
print()
for mode in sorted({r["mode"] for r in rows}):
    g = [r["gbps_steady"] for r in rows if r["mode"] == mode and "gbps_steady" in r]
    x = [r["retx"] for r in rows if r["mode"] == mode and r.get("retx") is not None]
    if g: print(f"{mode:5s} n={len(g)}  Gbit/s median {st.median(g):.2f}  range {min(g):.2f}-{max(g):.2f}  retransmits median {st.median(x):.0f}")
json.dump(rows, open(os.path.join(RUN, "summary.json"), "w"), indent=1)
