#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/common.sh"

ARCHIVE_PATH="$ROOT_DIR/artifacts/libcsp-v1.6-riscv64-linux-gnu.tar.gz"
STAGE_DIR="$ROOT_DIR/artifacts/$PACKAGE_ROOT"

do_step() {
    prepare_common_dirs
    require_file "$ROOT_DIR/utils/package_riscv_artifact.sh"
    require_file "$BUILD_DIR/libcsp.a"
    require_file "$BUILD_DIR/include/csp/csp_autoconfig.h"
    require_file "$RISCV_DEPS/lib/libsocketcan.a"
    require_file "$RISCV_DEPS/lib/libzmq.a"
    require_file "$RISCV_DEPS/lib/libbz2.a"
    require_file "$RISCV_DEPS/include/libsocketcan.h"
    require_file "$RISCV_DEPS/include/can_netlink.h"
    require_file "$RISCV_DEPS/include/zmq.h"
    require_file "$RISCV_DEPS/include/zmq_utils.h"
    require_file "$RISCV_DEPS/include/bzlib.h"
    require_file "$RISCV_DEPS/lib/pkgconfig/libsocketcan.pc"
    require_file "$RISCV_DEPS/lib/pkgconfig/libzmq.pc"

    run_checked "$ROOT_DIR/utils/package_riscv_artifact.sh"
}

validate_step() {
    [[ -f "$STAGE_DIR/lib/libcsp.a" ]] &&
    [[ -f "$STAGE_DIR/lib/libsocketcan.a" ]] &&
    [[ -f "$STAGE_DIR/lib/libzmq.a" ]] &&
    [[ -f "$STAGE_DIR/lib/libbz2.a" ]] &&
    [[ -f "$STAGE_DIR/include/libsocketcan.h" ]] &&
    [[ -f "$STAGE_DIR/include/can_netlink.h" ]] &&
    [[ -f "$STAGE_DIR/include/zmq.h" ]] &&
    [[ -f "$STAGE_DIR/include/zmq_utils.h" ]] &&
    [[ -f "$STAGE_DIR/include/bzlib.h" ]] &&
    [[ -f "$STAGE_DIR/include/csp/csp_autoconfig.h" ]] &&
    [[ -f "$STAGE_DIR/lib/pkgconfig/libsocketcan.pc" ]] &&
    [[ -f "$STAGE_DIR/lib/pkgconfig/libzmq.pc" ]] &&
    check_file_contains "$STAGE_DIR/lib/pkgconfig/libsocketcan.pc" 'prefix=${pcfiledir}/../..' &&
    check_file_contains "$STAGE_DIR/lib/pkgconfig/libzmq.pc" 'prefix=${pcfiledir}/../..' &&
    check_file_not_contains "$STAGE_DIR/lib/pkgconfig/libsocketcan.pc" "$RISCV_DEPS" &&
    check_file_not_contains "$STAGE_DIR/lib/pkgconfig/libzmq.pc" "$RISCV_DEPS" &&
    [[ -f "$ARCHIVE_PATH" ]] &&
    check_tar_contains "$ARCHIVE_PATH" "$PACKAGE_ROOT/lib/libcsp.a" &&
    check_tar_contains "$ARCHIVE_PATH" "$PACKAGE_ROOT/lib/libsocketcan.a" &&
    check_tar_contains "$ARCHIVE_PATH" "$PACKAGE_ROOT/lib/libzmq.a" &&
    check_tar_contains "$ARCHIVE_PATH" "$PACKAGE_ROOT/lib/libbz2.a" &&
    check_tar_contains "$ARCHIVE_PATH" "$PACKAGE_ROOT/include/libsocketcan.h" &&
    check_tar_contains "$ARCHIVE_PATH" "$PACKAGE_ROOT/include/can_netlink.h" &&
    check_tar_contains "$ARCHIVE_PATH" "$PACKAGE_ROOT/include/zmq.h" &&
    check_tar_contains "$ARCHIVE_PATH" "$PACKAGE_ROOT/include/zmq_utils.h" &&
    check_tar_contains "$ARCHIVE_PATH" "$PACKAGE_ROOT/include/bzlib.h" &&
    check_tar_contains "$ARCHIVE_PATH" "$PACKAGE_ROOT/include/csp/csp_autoconfig.h" &&
    check_tar_contains "$ARCHIVE_PATH" "$PACKAGE_ROOT/lib/pkgconfig/libsocketcan.pc" &&
    check_tar_contains "$ARCHIVE_PATH" "$PACKAGE_ROOT/lib/pkgconfig/libzmq.pc"
}

cleanup_step() {
    cleanup_path "$STAGE_DIR"
    cleanup_path "$ARCHIVE_PATH"
}

retry_once_after_cleanup "package-artifact" do_step validate_step cleanup_step
