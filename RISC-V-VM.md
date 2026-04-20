# Ubuntu `riscv64` VM on Arch: serial installer guide

This guide is for your current machine:

- Arch Linux
- `libvirt` installed
- `virt-manager` installed
- `qemu-system-riscv64` installed

The goal is an Ubuntu `riscv64` install that stays in the terminal and avoids the buggy graphical installer path.

## Short version

For Ubuntu on `riscv64`, the cleanest install flow is:

- use the real Ubuntu `riscv64` installer ISO
- run raw `qemu-system-riscv64`
- use `-nographic`
- do the whole install in one serial terminal

There is no magic `virt-install` flag that turns a flaky `riscv64` installer UI into a good one. The practical fix is to use the serial installer path from the start.

## Important note about the ISO already in this repo

You currently have:

```text
ubuntu-24.04.4-live-server-amd64.iso
```

That ISO is for `amd64`, not `riscv64`.

It cannot be used to install an Ubuntu `riscv64` guest.

## Why this guide uses a serial installer

You said the Ubuntu install path feels buggy and you want a better terminal experience.

That points to one clear approach:

- no graphical installer
- no attempt to make virt-manager the main path
- one terminal from boot to install to reboot

With `riscv64`, that is usually the least frustrating option.

## What this host already has

On this Arch host, I verified:

- `qemu-system-riscv64` is installed
- QEMU is `10.2.2`
- RISC-V EFI firmware is present
- RISC-V OpenSBI firmware is present

Useful local firmware paths already available on this machine:

```text
/usr/share/edk2/riscv64/RISCV_VIRT_CODE.fd
/usr/share/edk2/riscv64/RISCV_VIRT_VARS.fd
/usr/share/qemu/opensbi-riscv64-generic-fw_dynamic.bin
```

## Bootloader you can use in this repo

You already built a U-Boot binary in this repo:

```text
./u-boot/u-boot.bin
```

That is the file used by the commands below.

## Download the correct Ubuntu installer ISO

Work from the repo root:

```bash
cd /home/hugo/code/risc-vm
```

Download the official Ubuntu Server `riscv64` installer ISO:

```bash
curl -LO https://cdimage.ubuntu.com/releases/24.04.1/release/ubuntu-24.04.4-live-server-riscv64.iso
```

After that, you should have:

```text
ubuntu-24.04.4-live-server-riscv64.iso
```

## Create the install disk

Create a raw disk image for the VM:

```bash
truncate -s 20G ubuntu-riscv64-installer.raw
```

You can check it with:

```bash
ls -lh ubuntu-riscv64-installer.raw
```

## Run the Ubuntu serial installer

Run this from the repo root:

```bash
qemu-system-riscv64 \
  -machine virt \
  -m 4G \
  -smp 2 \
  -nographic \
  -kernel ./u-boot/u-boot.bin \
  -drive file=./ubuntu-riscv64-installer.raw,format=raw,if=virtio \
  -drive file=./ubuntu-24.04.4-live-server-riscv64.iso,format=raw,if=virtio,readonly=on \
  -netdev user,id=net0 \
  -device virtio-net-device,netdev=net0 \
  -device virtio-rng-pci \
  -cpu rva23s64
```

This is the important part:

- `-nographic` keeps the whole install in the terminal
- the ISO is the real Ubuntu `riscv64` installer
- the disk is your target install disk
- `virtio` is used for disk and network
- `rva23s64` matches Ubuntu's current `riscv64` QEMU guidance

## What to expect during install

You should see:

- boot messages in the terminal
- the Ubuntu server installer in text/serial mode
- the full install process in the same terminal session

That is the "nice terminal install" version of this setup. It is not fancy, but it avoids the flaky interface problem you were hitting.

## Boot the VM after installation

Yes, you can boot the VM again after installation.

Boot the same disk again, but remove the installer ISO from the QEMU command.

Use:

```bash
qemu-system-riscv64 \
  -machine virt \
  -m 4G \
  -smp 2 \
  -nographic \
  -kernel ./u-boot/u-boot.bin \
  -drive file=./ubuntu-riscv64-installer.raw,format=raw,if=virtio \
  -netdev user,id=net0 \
  -device virtio-net-device,netdev=net0 \
  -device virtio-rng-pci \
  -cpu rva23s64
```

The difference compared with the installer command is simple:

- keep the same disk file
- remove the ISO line

If you keep the installer ISO attached after installation, the VM may try to boot the installer again instead of booting the installed Ubuntu system.

## Networking in this setup

This raw QEMU installer command uses:

```text
-netdev user,id=net0
-device virtio-net-device,netdev=net0
```

That is user-mode networking from QEMU.

What that means:

- the VM should have outbound network access
- package downloads during install should work
- this is simpler than setting up a bridge

If you later want the installed Ubuntu VM under libvirt instead, you can switch to a managed libvirt VM after installation. For the installer itself, this raw serial setup is the simpler path.

## About `network=default` in libvirt

You asked about this earlier.

On this machine, libvirt's `default` network already exists and is active:

```bash
virsh -c qemu:///system net-list --all
virsh -c qemu:///system net-info default
```

So if you later choose to create a libvirt-managed Ubuntu VM, you do not need to create the `default` network first.

## If you want to inspect things in virt-manager

You can still use `virt-manager` for other VMs or later management, but it should not be the main install path for this Ubuntu `riscv64` setup.

For this case, raw QEMU plus `-nographic` is the path that best matches your goal.

## Troubleshooting

### The ISO is the wrong architecture

If the filename says `amd64`, it is wrong for a `riscv64` guest.

You need:

```text
ubuntu-24.04.4-live-server-riscv64.iso
```

not:

```text
ubuntu-24.04.4-live-server-amd64.iso
```

### The installer UI is buggy

Do not try to fix that with a GUI option.

Use the serial path:

```text
-nographic
```

That is the point of this guide.

### QEMU says the loader file is missing

If QEMU cannot find:

```text
./u-boot/u-boot.bin
```

then either:

- you are not running the command from the repo root
- or the U-Boot build output is missing

Check:

```bash
ls -lh ./u-boot/u-boot.bin
```

### The VM has no network during install

Double-check that these arguments are present:

```text
-netdev user,id=net0
-device virtio-net-device,netdev=net0
```

### The install feels slow

That is normal.

This is emulation, not native RISC-V hardware and not accelerated `x86_64` virtualization.

## Recommended next step

You already have the repo and the general setup.

The next practical sequence is:

```bash
cd /home/hugo/code/risc-vm
curl -LO https://cdimage.ubuntu.com/releases/24.04.1/release/ubuntu-24.04.4-live-server-riscv64.iso
truncate -s 20G ubuntu-riscv64-installer.raw
```

After that, use the post-install boot command in the section above with:

```text
./u-boot/u-boot.bin
./ubuntu-riscv64-installer.raw
```
