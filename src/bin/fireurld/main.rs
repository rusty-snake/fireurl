#![warn(rust_2018_idioms)]

use std::io::ErrorKind as IoErrorKind;
use std::os::unix::net::UnixDatagram;
use std::process::ExitCode;
use std::str;

fn main() -> Result<(), ExitCode> {
    // TODO: lnix
    let orig_umask = unsafe { libc::umask(0o077) };
    let socket = create_socket()?;
    unsafe { libc::umask(orig_umask) };

    loop {
        let mut buf = [0; 4096];
        let size = match socket.recv(&mut buf) {
            Ok(size) => size,
            Err(error) => {
                eprintln!("ERROR: Failed to recive message: {error}");
                continue;
            }
        };
        let url = match str::from_utf8(&buf[..size]) {
            Ok(url) => url,
            Err(error) => {
                eprintln!("ERROR: Received invalid UTF-8: {error}");
                continue;
            }
        };
        fireurl::open(&url);
    }
}

fn create_socket() -> Result<UnixDatagram, ExitCode> {
    match UnixDatagram::bind(fireurl::socket_path()) {
        Ok(socket) => Ok(socket),
        Err(error) => {
            eprintln!("ERROR: Failed to bind the socket: {error}");

            if error.kind() == IoErrorKind::AddrInUse {
                eprintln!(
                    "INFO: Make sure that fireurld is not running and delete '{}'.",
                    fireurl::socket_path().display()
                );

                Err(ExitCode::from(10))
            } else {
                Err(ExitCode::FAILURE)
            }
        }
    }
}
