#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/common.sh"

REPO="$SRC_ROOT/libsocketcan"

do_step() {
    prepare_common_dirs
    require_cmd git
    require_cmd autoreconf
    require_cmd make
    require_cmd bash
    require_cmd "$CC"
    require_cmd "$AR"
    require_cmd "$RANLIB"
    require_cmd pkg-config

    clone_or_update_repo "https://github.com/linux-can/libsocketcan.git" "$REPO"
    require_dir "$REPO"

    run_checked autoreconf -fi "$REPO"
    run_checked bash -lc "cd '$REPO' && ./configure \
        --host=riscv64-linux-gnu \
        --prefix='$RISCV_DEPS' \
        --enable-static \
        --disable-shared \
        CC='$CC' \
        AR='$AR' \
        RANLIB='$RANLIB'"
    run_checked make -C "$REPO" -j"$JOBS"
    run_checked make -C "$REPO" install
}

validate_step() {
    check_archive_members "$RISCV_DEPS/lib/libsocketcan.a" &&
    [[ -f "$RISCV_DEPS/lib/pkgconfig/libsocketcan.pc" ]] &&
    pkg-config --libs libsocketcan >/dev/null 2>&1 &&
    check_pkg_config_prefix libsocketcan
}

cleanup_step() {
    cleanup_path "$RISCV_DEPS/lib/libsocketcan.a"
    cleanup_path "$RISCV_DEPS/lib/pkgconfig/libsocketcan.pc"
    cleanup_path "$RISCV_DEPS/include/libsocketcan.h"
    if [[ -d "$REPO" ]]; then
        make -C "$REPO" clean >/dev/null 2>&1 || true
        cleanup_path "$REPO/autom4te.cache"
        cleanup_path "$REPO/config.status"
        cleanup_path "$REPO/config.log"
        cleanup_path "$REPO/Makefile"
        cleanup_path "$REPO/libtool"
    fi
}

retry_once_after_cleanup "build-libsocketcan" do_step validate_step cleanup_step
