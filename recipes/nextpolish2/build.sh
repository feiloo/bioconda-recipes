#!/bin/bash -exuo

# build statically linked binary with Rust
RUST_BACKTRACE=1 cargo install --verbose --path . --root "${PREFIX}"
