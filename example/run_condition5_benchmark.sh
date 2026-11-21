#!/usr/bin/env bash
set -e

# Ensure script executes within the example directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Target device resolution:
# 1. First positional argument ($1)
# 2. $DEVICE or $ANDROID_SERIAL environment variable
# 3. Automatic detection of connected device via ADB
TARGET_DEVICE="${1:-${DEVICE:-${ANDROID_SERIAL:-}}}"

if [ -z "$TARGET_DEVICE" ]; then
  if ! command -v adb &> /dev/null; then
    echo "❌ Error: 'adb' command not found. Please ensure Android SDK platform-tools are in your PATH."
    exit 1
  fi

  CONNECTED_DEVICES=($(adb devices | awk 'NR>1 && $2=="device" {print $1}'))
  NUM_DEVICES=${#CONNECTED_DEVICES[@]}

  if [ "$NUM_DEVICES" -eq 0 ]; then
    echo "❌ Error: No Android devices/emulators connected via ADB."
    echo "Please connect an Android device with USB debugging enabled, or start an emulator."
    exit 1
  elif [ "$NUM_DEVICES" -eq 1 ]; then
    TARGET_DEVICE="${CONNECTED_DEVICES[0]}"
    echo "ℹ️  Auto-detected connected Android device: $TARGET_DEVICE"
  else
    TARGET_DEVICE="${CONNECTED_DEVICES[0]}"
    echo "⚠️  Multiple devices detected: ${CONNECTED_DEVICES[*]}"
    echo "Using default device: $TARGET_DEVICE"
    echo "Tip: You can specify a device via: ./run_condition5_benchmark.sh <device_serial>"
  fi
fi

DEVICE="$TARGET_DEVICE"
FILTER="S1_,S2_,S3_,S4_,S5_"
TARGET="integration_test/gate_1b_benchmark_test.dart"
DRIVER="test_driver/perf_driver.dart"

DEVICE_MODEL=$(adb -s "$DEVICE" shell getprop ro.product.model 2>/dev/null | tr -d '\r\n')
DEVICE_MANUFACTURER=$(adb -s "$DEVICE" shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r\n')
ANDROID_VERSION=$(adb -s "$DEVICE" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r\n')
DEVICE_DISPLAY_NAME="${DEVICE_MANUFACTURER} ${DEVICE_MODEL}"
[ -z "$DEVICE_MODEL" ] && DEVICE_DISPLAY_NAME="Android Device"

echo "=== Hardware Condition Check: $DEVICE_DISPLAY_NAME ($DEVICE) ==="
echo "Android Release: $ANDROID_VERSION"

# Non-fatal hardware state verification and screen wake-up
adb -s "$DEVICE" shell dumpsys battery 2>/dev/null | grep -E "level|temperature|powered" || true
adb -s "$DEVICE" shell input keyevent KEYCODE_WAKEUP 2>/dev/null || true
adb -s "$DEVICE" shell wm dismiss-keyguard 2>/dev/null || true

# Persist device metadata for aggregation report
mkdir -p build/perf
cat <<EOF > build/perf/device_info.json
{
  "serial": "$DEVICE",
  "manufacturer": "$DEVICE_MANUFACTURER",
  "model": "$DEVICE_MODEL",
  "android_version": "$ANDROID_VERSION",
  "display_name": "$DEVICE_DISPLAY_NAME"
}
EOF

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
    -d "$DEVICE" \
    --driver="$DRIVER" \
    --target="$TARGET" \
    --dart-define=PERF_FILTER="$FILTER" \
    --dart-define=PERF_SAFETY_FLOOR="$floor" \
    --dart-define=PERF_CELL_K="$k" \
    --dart-define=PERF_MIN_FLOOR="$minFloor" \
    --dart-define=PERF_NO_INSTRUMENTATION="$noInst"

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

echo "=== ALL CONDITION 5 BENCHMARK RUNS COMPLETED SUCCESSFULLY FOR $DEVICE_DISPLAY_NAME ==="

if [ -f "aggregate_condition5.py" ]; then
  echo "Aggregating benchmark results..."
  python3 aggregate_condition5.py
fi
