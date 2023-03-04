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

# USAGE:
#   [MINISIGN="/path/to/secret.key"] [FIREURL_GIT_REF=<ref>] ./dist.sh

set -euo pipefail

# cd into the project directory
cd -P -- "$(readlink -e "$(dirname "$0")")"

me="$(basename "$0")"

#TODO: exec > >(tee "$me.log")

# Do not run if an old outdir exists
[ -d outdir ] && { echo "$me: Please delete 'outdir' first."; exit 1; }

# Check presents of non-standard programs (everything except coreutils and built-ins)
REQUIRED_PROGRAMS=(cargo git jq podman xz)
for program in "${REQUIRED_PROGRAMS[@]}"; do
	if ! command -v "$program" >&-; then
		echo "$me: Missing requirement: $program is not installed or could not be found."
		echo "Please make sure $program is installed and in \$PATH."
		exit 1
	fi
done

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

# Get RELEASE_ID: <name>-v<version>[+<sha1>]
TEMP_WORK_TREE=$(mktemp -d "${TMPDIR:-/tmp}/build-${PWD##*/}.XXXXXX")
# shellcheck disable=SC2064
trap "rm -r '$TEMP_WORK_TREE'" EXIT
for file in Cargo.toml Cargo.lock src/lib.rs; do
	mkdir -p "$TEMP_WORK_TREE/$(dirname "$file")"
	git show "${FIREURL_GIT_REF:-HEAD}:$file" > "$TEMP_WORK_TREE/$file"
done
RELEASE_ID=$(cargo metadata --manifest-path="$TEMP_WORK_TREE/Cargo.toml" --no-deps --format-version=1 | jq -j '.packages[0].name, "-v", .packages[0].version')
if [[ "${FIREURL_GIT_REF:-HEAD}" != v* ]]; then
	RELEASE_ID="$RELEASE_ID+$(git rev-parse --short "${FIREURL_GIT_REF:-HEAD}")"
fi
rm -r "$TEMP_WORK_TREE"
trap - EXIT

# Vendor all dependencies
cargo --color=never --locked vendor vendor
[ -d .cargo ] && mv -v .cargo .cargo.bak
mkdir -v .cargo
trap "rm -rv .cargo && [ -d .cargo.bak ] && mv -v .cargo.bak .cargo" EXIT
echo "$me: Creating .cargo/config.toml"
cat > .cargo/config.toml <<EOF
[source.crates-io]
replace-with = "vendored-sources"
[source.vendored-sources]
directory = "vendor"
EOF

mkdir -v outdir

# Create the source archive
echo "$me: Start to pack the source archive"
git archive --format=tar --prefix="$RELEASE_ID/" -o "outdir/$RELEASE_ID.src.tar" "${FIREURL_GIT_REF:-HEAD}"
tar --xform="s,^,$RELEASE_ID/," -rf "outdir/$RELEASE_ID.src.tar" .cargo vendor
xz "outdir/$RELEASE_ID.src.tar"

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
		tar --strip=1 -xf '/outdir/$RELEASE_ID.src.tar.xz'
		cargo build --release --frozen
		install -Dm0755 ./target/release/fireurl '$INSTALLDIR/bin/fireurl'
		install -Dm0755 ./target/release/fireurld '$INSTALLDIR/bin/fireurld'
		install -Dm0644 -t '$INSTALLDIR/share/doc/fireurl' CHANGELOG.md LICENSE README.md systemd/fireurld.service
		tar -cJf '/outdir/$RELEASE_ID-x86_64-unknown-linux-musl.tar.xz' -C '$INSTALLDIR' .
	"

# Compute checksums
(cd outdir; sha256sum -- *.tar.xz) > outdir/SHA256SUMS
(cd outdir; sha512sum -- *.tar.xz) > outdir/SHA512SUMS

if [[ -n "${MINISIGN:-}" ]] && command -v minisign >&-; then
	minisign -S -s "$MINISIGN" -m outdir/*
fi

echo "Success!"
