#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# Elastoplastic perforated plate regression test
# Checks strain, stress, and plastic yielding
# ============================================================

# Reference ranges (order-of-magnitude + robustness)
EPSILON_MIN=4.5e-3
EPSILON_MAX=6.0e-3

SIGMA_MIN=1.5e8
SIGMA_MAX=2.2e8

YIELD_MIN=28
YIELD_MAX=32

# Log files
SOLVER_LOGFILE="log.solids4Foam"
ALLRUN_LOGFILE="log.Allrun"

echo "=================================================================="
echo "Elastoplastic perforated plate regression test"
echo "Max epsilonEq                  in [${EPSILON_MIN}, ${EPSILON_MAX}]"
echo "Max sigmaEq (von Mises)        in [${SIGMA_MIN}, ${SIGMA_MAX}]"
echo "Yielding integration points    in [${YIELD_MIN}, ${YIELD_MAX}]"
echo "=================================================================="
echo

# Clean case
./Allclean > /dev/null 2>&1 || true

# Run case
./Allrun > "${ALLRUN_LOGFILE}" 2>&1

# ------------------------------------------------------------
# Extract helpers
# ------------------------------------------------------------

extract_max_epsilon() {
    grep "Max epsilonEq" "${SOLVER_LOGFILE}" \
        | awk '{print $NF}' \
        | tail -n 1
}

extract_max_sigma() {
    grep "Max sigmaEq (von Mises stress)" "${SOLVER_LOGFILE}" \
        | awk '{print $NF}' \
        | tail -n 1
}

extract_yielding() {
    grep "Number of yielding integration points =" "${SOLVER_LOGFILE}" \
        | tail -n 101 \
        | head -n 1 \
        | awk -F'[=/]' '{print $2}'
}

# ------------------------------------------------------------
# Extract values
# ------------------------------------------------------------

epsilon=$(extract_max_epsilon)
sigma=$(extract_max_sigma)
numYielding=$(extract_yielding)

if [[ -z "${epsilon}" || -z "${sigma}" || -z "${numYielding}" ]]
then
    echo "FAIL: Could not extract one or more regression quantities"
    exit 1
fi

# ------------------------------------------------------------
# Checks
# ------------------------------------------------------------

failures=0

# --- epsilonEq ---
if awk "BEGIN {exit !(${epsilon} >= ${EPSILON_MIN} && ${epsilon} <= ${EPSILON_MAX})}"
then
    printf "PASS: Max epsilonEq = %.6g\n" "${epsilon}"
else
    printf "FAIL: Max epsilonEq = %.6g\n" "${epsilon}"
    failures=$((failures + 1))
fi

# --- sigmaEq ---
if awk "BEGIN {exit !(${sigma} >= ${SIGMA_MIN} && ${sigma} <= ${SIGMA_MAX})}"
then
    printf "PASS: Max sigmaEq = %.6g\n" "${sigma}"
else
    printf "FAIL: Max sigmaEq = %.6g\n" "${sigma}"
    failures=$((failures + 1))
fi

# --- number of yielding integration points ---
if (( numYielding >= YIELD_MIN && numYielding <= YIELD_MAX ))
then
    printf "PASS: Number of yielding integration points = %d\n" "${numYielding}"
else
    printf "FAIL: Number of yielding integration points = %d\n" "${numYielding}"
    failures=$((failures + 1))
fi

# Clean case again
./Allclean > /dev/null 2>&1 || true

echo
if (( failures == 0 ))
then
    echo "============================================================"
    echo "Regression test PASSED"
    echo "============================================================"
    exit 0
else
    echo "============================================================"
    echo "Regression test FAILED (${failures} checks)"
    echo "============================================================"
    exit 1
fi
