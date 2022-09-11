# fireurl

Fixing the firejail URL open issue.

## Getting started

### Build & Install

    cargo build --release
    sudo install -Dm0755 target/release/fireurl /usr/local/bin/fireurl
    sudo install -Dm0755 target/release/fireurld /usr/local/libexec/fireurld

### Usage

TBW

## Architecture

Fireurl has a client (fireurl) and a server (fireurld) component.
A url is passed to the client on the command line. If it is running outside
of a container, it opens the url directly (using the `fireurl::open` function).
If it is running inside of a container, it send a request to fireurld, which
must run in the background at this time, via an UNIX domain socket to open the
url.
