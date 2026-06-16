---

# DELIVERABLE 2: FULL ARMBIAN BUILDER

Now the more advanced version — this uses the **Armbian build framework** to compile the OS from source WITH AJC pre-installed. This gives you a fully reproducible build system.

## `ajc-armbian-builder/README.md`

```markdown
# AJC PISOWIFI - Armbian Build System

## Overview

This is the PRODUCTION build system. Instead of provisioning a running
Orange Pi and then imaging it, this system:

1. Compiles an Armbian Linux image from source
2. Injects AJC PISOWIFI during the build
3. Outputs a ready-to-flash .img file

This is ideal for:
- Automated CI/CD pipelines (GitHub Actions)
- Reproducible builds
- Scaling to multiple board types
- Version tracking (each build is tagged)

## Quick Start

### PREREQUISITES

```bash
sudo apt install -y git curl wget \
    build-essential libncurses-dev \
    bison flex libssl-dev libelf-dev \
    bc cpio fakeroot \
    qemu-user-static binfmt-support \
    debootstrap