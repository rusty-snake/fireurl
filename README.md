# fireurl

Fixing the firejail URL open issue.

## Installation

### Binary

There is a statically linked 64-bit musl binary attached to very [release](https://github.com/rusty-snake/fireurl/releases).
You can install it system-wide:

```bash
FIREURL_VERSION=0.1.0
mkdir -p /opt/fireurl
curl --proto '=https' --tlsv1.3 -sSf -L "https://github.com/rusty-snake/fireurl/releases/download/v$FIREURL_VERSION/fireurl-v$FIREURL_VERSION-x86_64-unknown-linux-musl.tar.xz" | tar -xJf- -C /opt/fireurl --strip-components=3
```

or per user:

```bash
FIREURL_VERSION=0.1.0
mkdir -p ~/.local/opt/fireurl
curl --proto '=https' --tlsv1.3 -sSf -L "https://github.com/rusty-snake/fireurl/releases/download/v$FIREURL_VERSION/fireurl-v$FIREURL_VERSION-x86_64-unknown-linux-musl.tar.xz" | tar -xJf- -C ~/.local/opt/fireurl --strip-components=3
```


### From source

#### Prerequisites

 - [Rust](https://www.rust-lang.org/) >= 1.61

#### Build

```bash
cargo build --release
```

#### Install

```bash
install -Dm0755 target/release/fireurl /usr/local/bin/fireurl
install -Dm0755 target/release/fireurld /usr/local/libexec/fireurld
```

## Usage

TBW

## Start `fireurld` with systemd

In order to start fireurld with systemd, you need to create a service unit for it.
Run `systemctl --user edit --full --force fireurld.service`, paste [`systemd/fireurld.service`](systemd/fireurld.service)
and adjust it as necessary. You likely need to change the path to the `fireurld`
binary. Afterwards you can close the editor and execute
`systemctl --user enable --now fireurld.service`.

## Architecture

Fireurl has a client (fireurl) and a server (fireurld) component.
A url is passed to the client on the command line. If it is running outside
of a container, it opens the url directly (using the `fireurl::open` function).
If it is running inside of a container, it send a request to fireurld, which
must run in the background at this time, via an UNIX domain socket to open the
url.
