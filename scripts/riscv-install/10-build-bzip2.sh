#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/common.sh"

REPO="$SRC_ROOT/bzip2"

do_step() {
    prepare_common_dirs
    require_cmd make
    require_cmd git
    require_cmd "$CC"
    require_cmd "$AR"
    require_cmd "$RANLIB"

    clone_or_update_repo "https://sourceware.org/git/bzip2.git" "$REPO"
    require_dir "$REPO"

    run_checked make -C "$REPO" clean
    run_checked make -C "$REPO" \
        libbz2.a \
        bzip2 \
        bzip2recover \
        CC="$CC" \
        AR="$AR" \
        RANLIB="$RANLIB" \
        CFLAGS="-O2 -fPIC"
    run_checked make -C "$REPO" PREFIX="$RISCV_DEPS" install
}

validate_step() {
    check_archive_members "$RISCV_DEPS/lib/libbz2.a"
}

cleanup_step() {
    cleanup_path "$RISCV_DEPS/lib/libbz2.a"
    cleanup_path "$RISCV_DEPS/include/bzlib.h"
    if [[ -d "$REPO" ]]; then
        make -C "$REPO" clean >/dev/null 2>&1 || true
    fi
}

retry_once_after_cleanup "build-bzip2" do_step validate_step cleanup_step
