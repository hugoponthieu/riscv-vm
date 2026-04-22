#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/common.sh"

do_step() {
    prepare_common_dirs
    require_cmd sudo
    require_cmd pacman

    ensure_pacman_package git
    ensure_pacman_package base-devel
    ensure_pacman_package cmake
    ensure_pacman_package autoconf
    ensure_pacman_package automake
    ensure_pacman_package libtool
    ensure_pacman_package pkgconf
    ensure_pacman_package python
    ensure_pacman_package riscv64-linux-gnu-gcc
    ensure_pacman_package riscv64-linux-gnu-binutils
    ensure_pacman_package riscv64-linux-gnu-glibc
}

validate_step() {
    command -v "$CC" >/dev/null 2>&1 &&
    command -v "$CXX" >/dev/null 2>&1 &&
    command -v "$AR" >/dev/null 2>&1 &&
    command -v "$RANLIB" >/dev/null 2>&1 &&
    command -v "$STRIP" >/dev/null 2>&1 &&
    command -v make >/dev/null 2>&1 &&
    command -v git >/dev/null 2>&1 &&
    command -v cmake >/dev/null 2>&1 &&
    command -v autoreconf >/dev/null 2>&1 &&
    command -v python >/dev/null 2>&1 &&
    command -v pkg-config >/dev/null 2>&1 &&
    command -v nproc >/dev/null 2>&1
}

cleanup_step() {
    :
}

retry_once_after_cleanup "install-host-tools" do_step validate_step cleanup_step
