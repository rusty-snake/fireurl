# fireurl

Fixing the firejail URL open issue.

## Installation

### Binary

There is a statically linked 64-bit musl binary attached to very [release](https://github.com/rusty-snake/fireurl/releases).
You can install it system-wide:

```bash
curl --proto '=https' --tlsv1.3 -sSf -L https://github.com/rusty-snake/fireurl/releases/download/v0.1.0/fireurl-v0.1.0-x86_64-unknown-linux-musl.tar.xz" | tar -xJf- -C /opt/fireurl
```

or per user:

```bash
curl --proto '=https' --tlsv1.3 -sSf -L https://github.com/rusty-snake/fireurl/releases/download/v0.1.0/fireurl-v0.1.0-x86_64-unknown-linux-musl.tar.xz" | tar -xJf- -C ~/.local/opt/fireurl
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
Run `systemctl --user edit --full --force fireurld.service`, paste [`systemd/fireurld.serivce`](systemd/fireurld.serivce)
and adjust it a necessary. You likely need to change the path to the `fireurld`
binary. Afterwards you can close the editor and execute
`systemctl --user enable --now fireurld.service`.

## Architecture

Fireurl has a client (fireurl) and a server (fireurld) component.
A url is passed to the client on the command line. If it is running outside
of a container, it opens the url directly (using the `fireurl::open` function).
If it is running inside of a container, it send a request to fireurld, which
must run in the background at this time, via an UNIX domain socket to open the
url.
