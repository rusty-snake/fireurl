use std::env::{args_os, var_os};
use std::os::unix::net::UnixDatagram;
use std::os::unix::prelude::*;
use std::process::ExitCode;

fn main() -> ExitCode {
    /* url is expected at argv[1] */
    let url = match args_os().nth(1) {
        Some(url) => url,
        None => {
            eprintln!("USAGE: fireurl <URL>");
            return ExitCode::from(2);
        }
    };

    if var_os("container").is_none() {
        /* Not running in a container (firejail, flatpak, podman, ...), open url directly */
        fireurl::open(&url);
    } else {
        /* Running in a container, ask fireurld to open the url */
        let socket = UnixDatagram::unbound().expect("Failed to create unbound UNIX socket");
        match socket.send_to(url.as_bytes(), &fireurl::socket_path()) {
            // FIXME:
            //  > On success, returns the number of bytes written.
            //  Is there a possibility we send only a part of the url?
            //  If so this is likely a security relevant problem.
            Ok(_) => (),
            Err(error) => {
                eprintln!("ERROR: Failed to send url: {error}");
                return ExitCode::FAILURE;
            }
        }
    }

    ExitCode::SUCCESS
}
