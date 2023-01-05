#!/bin/bash

# Copyright © 2021,2023 rusty-snake
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

set -euo pipefail

# cd into the project directory
cd -P -- "$(readlink -e "$(dirname "$0")")"

me="$(basename "$0")"

#TODO: exec > >(tee "$me.log")

# Do not run if an old outdir exists
[ -d outdir ] && { echo "$me: Please delete 'outdir' first."; exit 1; }

# Check presents of non-standard programs (everything except coreutils and built-ins)
if ! command -v cargo >&-; then
	echo "$me: Missing requirement: cargo is not installed or could not be found."
	echo "Please make sure cargo is installed and in \$PATH."
	exit 1
fi
if ! command -v git >&-; then
	echo "$me: Missing requirement: git is not installed or could not be found."
	echo "Please make sure git is installed and in \$PATH."
	exit 1
fi
if ! command -v podman >&-; then
	echo "$me: Missing requirement: podman is not installed or could not be found."
	echo "Please make sure podman is installed and in \$PATH."
	exit 1
fi
if ! command -v xz >&-; then
	echo "$me: Missing requirement: xz is not installed or could not be found."
	echo "Please make sure xz is installed and in \$PATH."
	exit 1
fi

# Check working tree
if [[ -n "$(git status --porcelain)" ]]; then
	echo "$me: Working tree is not clean."
	echo "Please stash all changes: git stash --include-untracked"
	exit 1
fi

# Pull alpine image if necessary
if [[ -z "$(podman image list --noheading alpine:latest)" ]]; then
	podman pull docker.io/library/alpine:latest
fi

# Check if we are allowed to run podman
if [[ "$(podman run --rm alpine:latest echo "hello")" != "hello" ]]; then
	echo "$me: podman does not seem to work correctly."
	exit 1
fi

IFS='#' read -r PROJECT VERSION < <(basename "$(cargo pkgid)")
VERSION="v$VERSION"

# No dependencies ATM, nothing to vendor.
# # Vendor all dependencies
# cargo --color=never --locked vendor vendor
# [ -d .cargo ] && mv -v .cargo .cargo.bak
# mkdir -v .cargo
# trap "rm -rv .cargo && [ -d .cargo.bak ] && mv -v .cargo.bak .cargo" EXIT
# echo "$me: Creating .cargo/config.toml"
# cat > .cargo/config.toml <<EOF
# [source.crates-io]
# replace-with = "vendored-sources"
# [source.vendored-sources]
# directory = "vendor"
# EOF

mkdir -v outdir

# Create the source archive
echo "$me: Start to pack the source archive"
git archive --format=tar --prefix="$PROJECT-$VERSION/" -o "outdir/$PROJECT-$VERSION.src.tar" "${FIREURL_GIT_REF:-HEAD}"
# tar --xform="s,^,$PROJECT-$VERSION/," -rf "outdir/$PROJECT-$VERSION.src.tar" .cargo vendor
tar --xform="s,^,$PROJECT-$VERSION/," -rf "outdir/$PROJECT-$VERSION.src.tar"
xz "outdir/$PROJECT-$VERSION.src.tar"

# Build the project
echo "$me: Starting build"
BUILDDIR="/builddir"
INSTALLDIR="/installdir"
podman run --rm --security-opt=no-new-privileges --cap-drop=all \
	-v ./outdir:/outdir:z --tmpfs "$BUILDDIR" --tmpfs "$INSTALLDIR:mode=0755" \
	-w "$BUILDDIR" alpine:latest sh -euo pipefail -c "
		apk update
		apk upgrade ||:
		apk add curl gcc xz ||:
		curl --proto '=https' --tlsv1.3 -sSf 'https://sh.rustup.rs' | sh -s -- -y --profile minimal
		source ~/.cargo/env
		tar --strip=1 -xf '/outdir/$PROJECT-$VERSION.src.tar.xz'
		cargo build --release --frozen
		install -Dm0755 ./target/release/fireurl '$INSTALLDIR/bin/fireurl'
		install -Dm0755 ./target/release/fireurld '$INSTALLDIR/bin/fireurld'
		install -Dm0644 -t '$INSTALLDIR/share/doc/fireurl' CHANGELOG.md LICENSE README.md systemd/fireurld.service
		tar -cJf '/outdir/$PROJECT-$VERSION-x86_64-unknown-linux-musl.tar.xz' -C '$INSTALLDIR' .
	"

# Compute checksums
(cd outdir; sha256sum -- *.tar.xz) > outdir/SHA256SUMS
(cd outdir; sha512sum -- *.tar.xz) > outdir/SHA512SUMS

if [[ -n "${MINISIGN:-}" ]] && command -v minisign >&-; then
	minisign -S -s "$MINISIGN" -m outdir/*
fi

echo "Success!"
