#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
RISCV_DEPS="${RISCV_DEPS:-$ROOT_DIR/.riscv-deps}"
SRC_ROOT="${SRC_ROOT:-$ROOT_DIR/.cache/riscv-src}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build-riscv64}"
PACKAGE_ROOT="${PACKAGE_ROOT:-libcsp-riscv64-linux-gnu}"
JOBS="${JOBS:-$(nproc)}"

CC="${CC:-riscv64-linux-gnu-gcc}"
CXX="${CXX:-riscv64-linux-gnu-g++}"
AR="${AR:-riscv64-linux-gnu-ar}"
RANLIB="${RANLIB:-riscv64-linux-gnu-ranlib}"
STRIP="${STRIP:-riscv64-linux-gnu-strip}"

export ROOT_DIR RISCV_DEPS SRC_ROOT BUILD_DIR PACKAGE_ROOT JOBS
export CC CXX AR RANLIB STRIP
export PKG_CONFIG_LIBDIR="${PKG_CONFIG_LIBDIR:-$RISCV_DEPS/lib/pkgconfig:$RISCV_DEPS/share/pkgconfig}"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-$PKG_CONFIG_LIBDIR}"
unset PKG_CONFIG_SYSROOT_DIR

log() {
    printf '[install-riscv] %s\n' "$*"
}

die() {
    printf '[install-riscv] error: %s\n' "$*" >&2
    exit 1
}

run_checked() {
    log "running: $*"
    "$@"
}

cleanup_path() {
    local path="$1"
    if [[ -e "$path" ]]; then
        log "cleaning: $path"
        rm -rf "$path"
    fi
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

require_file() {
    [[ -f "$1" ]] || die "missing file: $1"
}

require_dir() {
    [[ -d "$1" ]] || die "missing directory: $1"
}

ensure_pacman_package() {
    local pkg="$1"
    if pacman -Q "$pkg" >/dev/null 2>&1; then
        log "package already installed: $pkg"
        return
    fi

    run_checked sudo pacman -S --needed --noconfirm "$pkg"
    pacman -Q "$pkg" >/dev/null 2>&1 || die "package install failed: $pkg"
}

clone_or_update_repo() {
    local url="$1"
    local dest="$2"

    if [[ -d "$dest/.git" ]]; then
        run_checked git -C "$dest" fetch --all --tags
        run_checked git -C "$dest" pull --ff-only
    elif [[ -d "$dest" ]]; then
        die "path exists but is not a git repo: $dest"
    else
        run_checked git clone "$url" "$dest"
    fi

    require_dir "$dest/.git"
}

verify_pkg_config_prefix() {
    local pkg="$1"
    local variable="${2:-prefix}"
    local value

    value="$(pkg-config --variable="$variable" "$pkg" 2>/dev/null || true)"
    [[ -n "$value" ]] || die "pkg-config could not resolve ${variable} for $pkg"

    case "$value" in
        "$RISCV_DEPS"*) ;;
        *) die "pkg-config for $pkg resolved to host prefix: $value" ;;
    esac
}

check_archive_members() {
    local archive="$1"
    [[ -f "$archive" ]] || return 1
    [[ -n "$(ar t "$archive" 2>/dev/null | head -n 1)" ]]
}

check_pkg_config_prefix() {
    local pkg="$1"
    local variable="${2:-prefix}"
    local value

    value="$(pkg-config --variable="$variable" "$pkg" 2>/dev/null || true)"
    [[ -n "$value" ]] || return 1

    case "$value" in
        "$RISCV_DEPS"*) return 0 ;;
        *) return 1 ;;
    esac
}

check_tar_contains() {
    local archive="$1"
    local pattern="$2"

    [[ -f "$archive" ]] || return 1
    tar -tzf "$archive" 2>/dev/null | grep -Fx "$pattern" >/dev/null 2>&1
}

check_file_contains() {
    local path="$1"
    local pattern="$2"

    [[ -f "$path" ]] || return 1
    grep -F -- "$pattern" "$path" >/dev/null 2>&1
}

check_file_not_contains() {
    local path="$1"
    local pattern="$2"

    [[ -f "$path" ]] || return 1
    ! grep -F -- "$pattern" "$path" >/dev/null 2>&1
}

print_step_success() {
    log "step succeeded: $1"
}

retry_once_after_cleanup() {
    local step_name="$1"
    local do_fn="$2"
    local validate_fn="$3"
    local cleanup_fn="$4"
    local attempt
    local rc

    for attempt in 1 2; do
        set +e
        ( set -e; "$do_fn" )
        rc=$?
        set -e

        if [[ "$rc" -eq 0 ]] && "$validate_fn"; then
            print_step_success "$step_name"
            return 0
        fi

        if [[ "$attempt" -eq 1 ]]; then
            log "validation failed for $step_name, cleaning and retrying once"
            "$cleanup_fn"
        fi
    done

    die "step failed after retry: $step_name"
}

prepare_common_dirs() {
    mkdir -p "$RISCV_DEPS" "$SRC_ROOT"
    require_dir "$ROOT_DIR"
}
