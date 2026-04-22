#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/common.sh"

do_step() {
    prepare_common_dirs
    require_file "$ROOT_DIR/waf"
    require_file "$ROOT_DIR/wscript"

    run_checked "$ROOT_DIR/waf" configure \
        --out="$BUILD_DIR" \
        --toolchain=riscv64-linux-gnu- \
        --with-os=posix \
        --enable-if-zmqhub \
        --enable-can-socketcan
    run_checked "$ROOT_DIR/waf" build --out="$BUILD_DIR"
}

validate_step() {
    [[ -f "$BUILD_DIR/libcsp.a" ]] &&
    [[ -f "$BUILD_DIR/include/csp/csp_autoconfig.h" ]] &&
    [[ -f "$BUILD_DIR/config.log" ]]
}

cleanup_step() {
    cleanup_path "$BUILD_DIR"
}

retry_once_after_cleanup "build-libcsp" do_step validate_step cleanup_step
