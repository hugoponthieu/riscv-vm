#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEP_DIR="$ROOT_DIR/scripts/riscv-install"

export ROOT_DIR

printf '[install-riscv] running: %s\n' "$STEP_DIR/00-install-host-tools.sh"
"$STEP_DIR/00-install-host-tools.sh"
printf '[install-riscv] running: %s\n' "$STEP_DIR/10-build-bzip2.sh"
"$STEP_DIR/10-build-bzip2.sh"
printf '[install-riscv] running: %s\n' "$STEP_DIR/20-build-libsocketcan.sh"
"$STEP_DIR/20-build-libsocketcan.sh"
printf '[install-riscv] running: %s\n' "$STEP_DIR/30-build-libzmq.sh"
"$STEP_DIR/30-build-libzmq.sh"
printf '[install-riscv] running: %s\n' "$STEP_DIR/40-verify-deps.sh"
"$STEP_DIR/40-verify-deps.sh"
printf '[install-riscv] running: %s\n' "$STEP_DIR/50-build-libcsp.sh"
"$STEP_DIR/50-build-libcsp.sh"
printf '[install-riscv] running: %s\n' "$STEP_DIR/60-package-artifact.sh"
"$STEP_DIR/60-package-artifact.sh"

printf '[install-riscv] completed full RISC-V install flow\n'
printf '[install-riscv] dependency prefix: %s\n' "${RISCV_DEPS:-$ROOT_DIR/.riscv-deps}"
printf '[install-riscv] libcsp archive: %s\n' "${BUILD_DIR:-$ROOT_DIR/build-riscv64}/libcsp.a"
printf '[install-riscv] staged sdk: %s\n' "$ROOT_DIR/artifacts/${PACKAGE_ROOT:-libcsp-riscv64-linux-gnu}"
printf '[install-riscv] tarball: %s\n' "$ROOT_DIR/artifacts/libcsp-v1.6-riscv64-linux-gnu.tar.gz"
printf '[install-riscv] this flow rebuilds the SDK only; downstream ELF runtime checks happen in the consumer build\n'
printf '[install-riscv] inspect with: tar -tzf %s\n' "$ROOT_DIR/artifacts/libcsp-v1.6-riscv64-linux-gnu.tar.gz"
printf '[install-riscv] extract with: tar -xzf %s\n' "$ROOT_DIR/artifacts/libcsp-v1.6-riscv64-linux-gnu.tar.gz"
