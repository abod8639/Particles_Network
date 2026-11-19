#!/usr/bin/env bash
set -e

DEVICE="RF8M3106KPD"
FILTER="S1_,S2_,S3_,S4_,S5_"
TARGET="integration_test/gate_1b_benchmark_test.dart"
DRIVER="test_driver/perf_driver.dart"

echo "=== Galaxy S10 Hardware Condition Check ==="
adb -s $DEVICE shell dumpsys battery | grep -E "level|temperature|powered"
adb -s $DEVICE shell input keyevent KEYCODE_WAKEUP
adb -s $DEVICE shell wm dismiss-keyguard

run_pass() {
  local label="$1"
  local floor="$2"
  local k="$3"
  local minFloor="$4"
  local noInst="$5"

  echo "--------------------------------------------------------"
  echo "Starting Benchmark Pass: $label"
  echo "Params: floor=$floor, k=$k, minFloor=$minFloor, noInst=$noInst"
  echo "--------------------------------------------------------"

  PERF_LABEL="$label" \
  PERF_SECONDS=3 \
  flutter drive --profile \
    -d $DEVICE \
    --driver=$DRIVER \
    --target=$TARGET \
    --dart-define=PERF_FILTER=$FILTER \
    --dart-define=PERF_SAFETY_FLOOR=$floor \
    --dart-define=PERF_CELL_K=$k \
    --dart-define=PERF_MIN_FLOOR=$minFloor \
    --dart-define=PERF_NO_INSTRUMENTATION=$noInst

  echo "Completed: $label. Cooling down for 5s..."
  sleep 5
}

# Alternating runs (3 pairs):
run_pass "c5_pass1_baseline" "20.0" "1.0" "20.0" "false"
run_pass "c5_pass1_optA"     "4.0"  "4.0" "4.0"  "false"

run_pass "c5_pass2_baseline" "20.0" "1.0" "20.0" "false"
run_pass "c5_pass2_optA"     "4.0"  "4.0" "4.0"  "false"

run_pass "c5_pass3_baseline" "20.0" "1.0" "20.0" "false"
run_pass "c5_pass3_optA"     "4.0"  "4.0" "4.0"  "false"

# Instrumentation overhead check:
run_pass "c5_optA_no_inst"   "4.0"  "4.0" "4.0"  "true"

echo "=== ALL CONDITION 5 BENCHMARK RUNS COMPLETED SUCCESSFULLY ==="
