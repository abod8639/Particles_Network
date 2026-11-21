#!/usr/bin/env python3
import json
import glob
import os
import sys
from statistics import median

def get_device_info():
    info_path = "build/perf/device_info.json"
    if os.path.exists(info_path):
        try:
            with open(info_path, 'r') as f:
                info = json.load(f)
                display_name = info.get("display_name", "").strip()
                android_ver = info.get("android_version", "").strip()
                serial = info.get("serial", "").strip()
                if display_name:
                    extra = []
                    if android_ver:
                        extra.append(f"Android {android_ver}")
                    if serial:
                        extra.append(f"Serial: {serial}")
                    details = f" ({', '.join(extra)})" if extra else ""
                    return f"{display_name}{details}"
        except Exception:
            pass

    # Check environment variable
    env_device = os.environ.get("BENCHMARK_DEVICE")
    if env_device:
        return env_device

    # Fallback to adb if connected
    try:
        import subprocess
        model = subprocess.check_output(
            ["adb", "shell", "getprop", "ro.product.model"],
            stderr=subprocess.DEVNULL, timeout=2
        ).decode('utf-8').strip()
        manu = subprocess.check_output(
            ["adb", "shell", "getprop", "ro.product.manufacturer"],
            stderr=subprocess.DEVNULL, timeout=2
        ).decode('utf-8').strip()
        if model:
            return f"{manu} {model}".strip()
    except Exception:
        pass

    return "Android Device"

def load_run(label):
    path = f"build/perf/{label}.json"
    if not os.path.exists(path):
        print(f"Warning: {path} not found")
        return None
    with open(path, 'r') as f:
        return json.load(f).get('scenarios', {})

def extract_metrics(scenario_data_list):
    res = {}
    if not scenario_data_list or None in scenario_data_list:
        return None
    keys = scenario_data_list[0].keys()
    for k in keys:
        vals = [d[k] for d in scenario_data_list if k in d]
        if not vals:
            continue
        if isinstance(vals[0], (int, float)):
            med_val = median(vals)
            min_val = min(vals)
            max_val = max(vals)
            res[k] = {
                'med': med_val,
                'min': min_val,
                'max': max_val,
                'vals': vals
            }
        else:
            res[k] = vals[0]
    return res

def main():
    device_name = get_device_info()
    if len(sys.argv) > 1 and not sys.argv[1].startswith("-"):
        device_name = sys.argv[1]

    b_passes = [load_run(f"c5_pass{i}_baseline") for i in [1, 2, 3]]
    a_passes = [load_run(f"c5_pass{i}_optA") for i in [1, 2, 3]]
    no_inst = load_run("c5_optA_no_inst")

    all_scenarios = list(b_passes[0].keys()) if b_passes[0] else []
    
    print(f"# Condition 5 Benchmark Results: {device_name}")
    print("\n## 1. Full Comparison Table: Baseline vs Option A (Median and [Min, Max] Run-to-Run Spread)\n")
    print("| Scenario | Config | Checks | Accepted | Ratio | Scan p50 (ms) | Grid Build (ms) | Physics (ms) | Emission (ms) | UI p50 (ms) | UI p90 (ms) | UI p99 (ms) | Worst UI (ms) | Raster p50 (ms) | FPS |")
    print("| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |")

    for s in all_scenarios:
        b_data = extract_metrics([p.get(s, {}) for p in b_passes if p and s in p])
        a_data = extract_metrics([p.get(s, {}) for p in a_passes if p and s in p])

        if b_data:
            c = int(b_data['candidate_checks']['med'])
            acc = int(b_data['accepted_pairs']['med'])
            r = b_data['ratio']['med']
            scan = f"{b_data['scan_loop_p50_ms']['med']:.2f} [{b_data['scan_loop_p50_ms']['min']:.2f}-{b_data['scan_loop_p50_ms']['max']:.2f}]"
            gb = f"{b_data['grid_build_ms']['med']:.2f}"
            ph = f"{b_data['physics_ms']['med']:.2f}"
            em = f"{b_data['emission_ms']['med']:.2f}"
            u50 = f"{b_data['build_p50_ms']['med']:.2f} [{b_data['build_p50_ms']['min']:.2f}-{b_data['build_p50_ms']['max']:.2f}]"
            u90 = f"{b_data['build_p90_ms']['med']:.2f}"
            u99 = f"{b_data['build_p99_ms']['med']:.2f}"
            w = f"{b_data['build_worst_ms']['med']:.2f}" if 'build_worst_ms' in b_data else "N/A"
            rst = f"{b_data['raster_p50_ms']['med']:.2f}"
            fps = f"{b_data['fps']['med']:.1f}"
            print(f"| `{s}` | Baseline | {c:,} | {acc:,} | {r:.2f}x | {scan} | {gb} | {ph} | {em} | {u50} | {u90} | {u99} | {w} | {rst} | {fps} |")

        if a_data:
            c = int(a_data['candidate_checks']['med'])
            acc = int(a_data['accepted_pairs']['med'])
            r = a_data['ratio']['med']
            scan = f"{a_data['scan_loop_p50_ms']['med']:.2f} [{a_data['scan_loop_p50_ms']['min']:.2f}-{a_data['scan_loop_p50_ms']['max']:.2f}]"
            gb = f"{a_data['grid_build_ms']['med']:.2f}"
            ph = f"{a_data['physics_ms']['med']:.2f}"
            em = f"{a_data['emission_ms']['med']:.2f}"
            u50 = f"{a_data['build_p50_ms']['med']:.2f} [{a_data['build_p50_ms']['min']:.2f}-{a_data['build_p50_ms']['max']:.2f}]"
            u90 = f"{a_data['build_p90_ms']['med']:.2f}"
            u99 = f"{a_data['build_p99_ms']['med']:.2f}"
            w = f"{a_data['build_worst_ms']['med']:.2f}" if 'build_worst_ms' in a_data else "N/A"
            rst = f"{a_data['raster_p50_ms']['med']:.2f}"
            fps = f"{a_data['fps']['med']:.1f}"
            print(f"| `{s}` | **Option A** | **{c:,}** | **{acc:,}** | **{r:.2f}x** | **{scan}** | {gb} | {ph} | {em} | **{u50}** | {u90} | {u99} | {w} | {rst} | **{fps}** |")

    if no_inst:
        print("\n## 2. Instrumentation Overhead (Option A with Instrumentation ON vs OFF)\n")
        print("| Scenario | Inst ON UI p50 (ms) | Inst OFF UI p50 (ms) | Delta (Overhead) | Inst ON FPS | Inst OFF FPS |")
        print("| :--- | :--- | :--- | :--- | :--- | :--- |")
        for s in all_scenarios:
            a_data = extract_metrics([p.get(s, {}) for p in a_passes if p and s in p])
            ni_data = no_inst.get(s, {})
            if a_data and ni_data:
                on_p50 = a_data['build_p50_ms']['med']
                off_p50 = ni_data.get('build_p50_ms', 0.0)
                delta = on_p50 - off_p50
                on_fps = a_data['fps']['med']
                off_fps = ni_data.get('fps', 0.0)
                print(f"| `{s}` | {on_p50:.2f} ms | {off_p50:.2f} ms | {delta:+.2f} ms ({(delta/off_p50*100) if off_p50>0 else 0:+.1f}%) | {on_fps:.1f} | {off_fps:.1f} |")

if __name__ == '__main__':
    main()
