#!/usr/bin/env python3
"""~/bench/summarize_suite.py RUN_DIR      — step-4 results per run, then median and range per mode
   ~/bench/summarize_suite.py RUN_DIR/rN_mode --one  — one-line summary of a single run"""
import json, sys, glob, os, statistics as st

def mpstat(fn):
    hdr, out = None, {}
    try: lines = open(fn, errors="ignore").read().splitlines()
    except OSError: return {}
    for line in lines:
        f = line.split()
        if len(f) > 3 and f[0] == "Average:" and f[1] == "CPU": hdr = f
        elif hdr and len(f) == len(hdr) and f[0] == "Average:":
            try: out[f[1]] = dict(zip(hdr[2:], map(float, f[2:])))
            except ValueError: pass
    return out

def cores(fn, cols=None):
    """Cores' worth of CPU: busy (100-%idle) if cols is None, else the sum of the given columns."""
    m = mpstat(fn); c = [k for k in m if k != "all"]
    if not c or "all" not in m: return None
    pct = (100 - m["all"]["%idle"]) if cols is None else sum(m["all"].get(x, 0.0) for x in cols)
    return round(pct * len(c) / 100, 2)

def vhost(fn):
    tot = 0.0
    try:
        for line in open(fn, errors="ignore"):
            f = line.split()
            if len(f) >= 11 and f[0] == "Average:" and f[2] == "-" and "vhost" in f[-1]: tot += float(f[8])
    except (OSError, ValueError): return None
    return round(tot / 100, 2)

def cpu(d):
    j = lambda n: os.path.join(d, n)
    return {"host_kernel": cores(j("host_mpstat.txt"), ["%sys", "%soft", "%irq"]),
            "host_guest": cores(j("host_mpstat.txt"), ["%guest"]), "vhost": vhost(j("host_pidstat.txt")),
            "vm1": cores(j("vm1_mpstat.txt")), "vm2": cores(j("vm2_mpstat.txt")), "arm": cores(j("arm_mpstat.txt"))}

def netperf(fn):
    kv = {}
    try:
        for line in open(fn, errors="ignore"):
            if "=" in line: k, v = line.strip().split("=", 1); kv[k] = v
    except OSError: pass
    def num(k):
        try: return float(kv[k])
        except (KeyError, ValueError): return None
    return {k: num(n) for k, n in (("tps", "THROUGHPUT"), ("mean_us", "MEAN_LATENCY"),
            ("p50_us", "P50_LATENCY"), ("p99_us", "P99_LATENCY"))}

def iperf(fn):
    try:
        e = json.load(open(fn))["end"]["sum_sent"]; return round(e["bits_per_second"] / 1e9, 2), e.get("retransmits")
    except Exception: return None, None

def samples(fn):
    v = {}
    try:
        for line in open(fn, errors="ignore"):
            f = line.split()
            if len(f) >= 3 and f[0] in ("tx_a", "tx_b", "rx_a", "rx_b"): v[f[0]] = [float(x) for x in f[1:]]
    except (OSError, ValueError): pass
    return v

def mpps(a, b, i=1):
    if not a or not b or b[0] <= a[0]: return None
    return round((b[i] - a[i]) / (b[0] - a[0]) / 1e6, 3)

def one(d):
    run = os.path.basename(d.rstrip("/")); r = {"run": run, "mode": run.split("_", 1)[1]}
    r["fixed_gbps"], r["fixed_retx"] = iperf(os.path.join(d, "fixed/iperf.json"))
    r.update({"fixed_" + k: v for k, v in cpu(os.path.join(d, "fixed")).items()})
    for t in ("rr_idle", "rr_load"):
        n = netperf(os.path.join(d, t, "netperf.txt"))
        r.update({t + "_" + k: n[k] for k in ("tps", "p50_us", "p99_us")})
    r["crr_tps"] = netperf(os.path.join(d, "crr/netperf.txt"))["tps"]; r["crr_arm"] = cpu(os.path.join(d, "crr"))["arm"]
    for p in sorted(glob.glob(os.path.join(d, "pps_*")), key=lambda x: int(x.rsplit("_", 1)[1])):
        s = p.rsplit("_", 1)[1]; tx = samples(os.path.join(p, "pktgen.txt")); rx = samples(os.path.join(p, "rx.txt"))
        r["pps%s_tx_M" % s] = mpps(tx.get("tx_a"), tx.get("tx_b"))
        r["pps%s_rx_M" % s] = mpps(rx.get("rx_a"), rx.get("rx_b"))
        r["pps%s_rxdrop_M" % s] = mpps(rx.get("rx_a"), rx.get("rx_b"), 2)
        r["pps%s_arm" % s] = cpu(p)["arm"]
    return r

if __name__ == "__main__":
    if "--one" in sys.argv:
        r = one(sys.argv[1]); keep = ("fixed_gbps", "fixed_host_kernel", "fixed_vhost", "fixed_arm", "rr_idle_p50_us",
                                      "rr_load_p99_us", "crr_tps", "pps64_rx_M", "pps1500_rx_M")
        print(" ".join("%s=%s" % (k, r.get(k)) for k in keep)); sys.exit(0)
    rows = [one(d) for d in sorted(glob.glob(os.path.join(sys.argv[1], "r*_*")))]
    for r in rows: print(json.dumps(r))
    keys = [k for k in rows[0] if k not in ("run", "mode")] if rows else []
    for m in sorted({r["mode"] for r in rows}):
        print("\n== %s" % m)
        for k in keys:
            v = [r[k] for r in rows if r["mode"] == m and isinstance(r.get(k), (int, float))]
            if v: print("  %-20s n=%d  median %-10s range %s - %s" % (k, len(v), round(st.median(v), 3), min(v), max(v)))
