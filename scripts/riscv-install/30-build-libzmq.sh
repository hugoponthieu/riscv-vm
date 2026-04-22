#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/common.sh"

REPO="$SRC_ROOT/libzmq"

do_step() {
    prepare_common_dirs
    require_cmd git
    require_cmd cmake
    require_cmd pkg-config
    require_cmd "$CC"
    require_cmd "$CXX"
    require_cmd "$AR"
    require_cmd "$RANLIB"

    clone_or_update_repo "https://github.com/zeromq/libzmq.git" "$REPO"
    require_dir "$REPO"

    run_checked cmake -S "$REPO" -B "$REPO/build-riscv" \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_C_COMPILER="$CC" \
        -DCMAKE_CXX_COMPILER="$CXX" \
        -DCMAKE_AR="$AR" \
        -DCMAKE_RANLIB="$RANLIB" \
        -DCMAKE_INSTALL_PREFIX="$RISCV_DEPS" \
        -DBUILD_SHARED=OFF \
        -DBUILD_STATIC=ON \
        -DENABLE_WS=OFF \
        -DWITH_TLS=OFF \
        -DZMQ_BUILD_TESTS=OFF \
        -DWITH_PERF_TOOL=OFF
    run_checked cmake --build "$REPO/build-riscv" -j"$JOBS"
    run_checked cmake --install "$REPO/build-riscv"
}

validate_step() {
    check_archive_members "$RISCV_DEPS/lib/libzmq.a" &&
    [[ -f "$RISCV_DEPS/lib/pkgconfig/libzmq.pc" ]] &&
    pkg-config --libs libzmq >/dev/null 2>&1 &&
    check_pkg_config_prefix libzmq
}

cleanup_step() {
    cleanup_path "$REPO/build-riscv"
    cleanup_path "$RISCV_DEPS/lib/libzmq.a"
    cleanup_path "$RISCV_DEPS/lib/pkgconfig/libzmq.pc"
    cleanup_path "$RISCV_DEPS/include/zmq.h"
    cleanup_path "$RISCV_DEPS/include/zmq_utils.h"
}

retry_once_after_cleanup "build-libzmq" do_step validate_step cleanup_step
