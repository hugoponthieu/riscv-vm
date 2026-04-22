#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/common.sh"

do_step() {
    prepare_common_dirs
    require_cmd pkg-config

    require_file "$RISCV_DEPS/lib/libbz2.a"
    require_file "$RISCV_DEPS/lib/libsocketcan.a"
    require_file "$RISCV_DEPS/lib/pkgconfig/libsocketcan.pc"
    require_file "$RISCV_DEPS/lib/libzmq.a"
    require_file "$RISCV_DEPS/lib/pkgconfig/libzmq.pc"
    require_file "$RISCV_DEPS/include/bzlib.h"
    require_file "$RISCV_DEPS/include/libsocketcan.h"
    require_file "$RISCV_DEPS/include/zmq.h"
    require_file "$RISCV_DEPS/include/zmq_utils.h"

    run_checked pkg-config --cflags libsocketcan
    run_checked pkg-config --libs libsocketcan
    run_checked pkg-config --static --libs libsocketcan
    run_checked pkg-config --cflags libzmq
    run_checked pkg-config --libs libzmq
    run_checked pkg-config --static --libs libzmq
}

validate_step() {
    check_archive_members "$RISCV_DEPS/lib/libbz2.a" &&
    check_archive_members "$RISCV_DEPS/lib/libsocketcan.a" &&
    check_archive_members "$RISCV_DEPS/lib/libzmq.a" &&
    check_pkg_config_prefix libsocketcan &&
    check_pkg_config_prefix libzmq &&
    check_file_contains "$RISCV_DEPS/lib/pkgconfig/libzmq.pc" 'Libs.private:' &&
    check_file_contains "$RISCV_DEPS/lib/pkgconfig/libzmq.pc" '-lstdc++' &&
    check_file_contains "$RISCV_DEPS/lib/pkgconfig/libsocketcan.pc" "$RISCV_DEPS" &&
    check_file_contains "$RISCV_DEPS/lib/pkgconfig/libzmq.pc" "$RISCV_DEPS"
}

cleanup_step() {
    :
}

retry_once_after_cleanup "verify-deps" do_step validate_step cleanup_step
