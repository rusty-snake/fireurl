#![warn(rust_2018_idioms)]

use std::env::{args, var_os};
use std::os::unix::net::UnixDatagram;
use std::process::ExitCode;

fn main() -> ExitCode {
    /* url is expected at argv[1] */
    let url = match args().nth(1) {
        Some(url) => url,
        None => {
            eprintln!("USAGE: fireurl <URL>");
            return ExitCode::from(2);
        }
    };

    if !fireurl::is_uri_trustworthy(&url) {
        eprintln!("INFO: Not opening uri that failed check.");
        return ExitCode::from(5);
    }

    if var_os("container").is_none() {
        /* Not running in a container (firejail, flatpak, podman, ...), open url directly */
        fireurl::open(&url, "FIREURL_BROWSER");
    } else {
        /* Running in a container, ask fireurld to open the url */
        let socket = UnixDatagram::unbound().expect("Failed to create unbound UNIX socket");
        match socket.send_to(url.as_bytes(), fireurl::socket_path()) {
            Ok(_) => (),
            Err(error) => {
                eprintln!("ERROR: Failed to send url: {error}");
                return ExitCode::FAILURE;
            }
        }
    }

    ExitCode::SUCCESS
}
