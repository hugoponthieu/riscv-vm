# Build U-Boot for Ubuntu `riscv64` install on Arch

This note is for building the `qemu-riscv64_smode` U-Boot binary used by the Ubuntu `riscv64` serial installer flow.

## Correct `CROSS_COMPILE` value

On this machine, the installed cross-toolchain binaries are:

```text
/bin/riscv64-linux-gnu-gcc
/bin/riscv64-linux-gnu-ld
/bin/riscv64-linux-gnu-objcopy
```

So the correct prefix is:

```bash
CROSS_COMPILE=riscv64-linux-gnu-
```

The trailing `-` matters.

## Important `ARCH` value

For 64-bit RISC-V U-Boot, use:

```bash
ARCH=riscv
```

Do not set:

```bash
ARCH=riscv64
```

## Minimal build sequence

From a fresh U-Boot checkout:

```bash
export ARCH=riscv
export CROSS_COMPILE=riscv64-linux-gnu-

make qemu-riscv64_smode_defconfig
make -j"$(nproc)"
```

## One-line version

If you do not want to export variables:

```bash
make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- qemu-riscv64_smode_defconfig
make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- -j"$(nproc)"
```

## Output file

After a successful build, the file you want is typically:

```text
u-boot.bin
```

You can then use it in the Ubuntu serial installer command like this:

```bash
qemu-system-riscv64 \
  -machine virt \
  -m 4G \
  -smp 2 \
  -nographic \
  -kernel /path/to/u-boot.bin \
  -drive file=./ubuntu-riscv64-installer.raw,format=raw,if=virtio \
  -drive file=./ubuntu-24.04.4-live-server-riscv64.iso,format=raw,if=virtio,readonly=on \
  -netdev user,id=net0 \
  -device virtio-net-device,netdev=net0 \
  -device virtio-rng-pci \
  -cpu rva23s64
```

## Quick sanity checks

Check that the compiler exists:

```bash
riscv64-linux-gnu-gcc --version
```

Check that the build output exists:

```bash
find . -name u-boot.bin
```
