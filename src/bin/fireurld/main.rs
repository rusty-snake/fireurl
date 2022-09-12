use std::io::ErrorKind as IoErrorKind;
use std::os::unix::net::UnixDatagram;
use std::process::ExitCode;
use std::str;

fn main() -> ExitCode {
    let socket = match UnixDatagram::bind(fireurl::socket_path()) {
        Ok(socket) => socket,
        Err(error) if error.kind() == IoErrorKind::AddrInUse => {
            eprintln!("ERROR: Failed to bind the socket: {error}");
            eprintln!(
                "INFO: Make sure that fireurld is not running and delete '{}'.",
                fireurl::socket_path().display()
            );
            return ExitCode::from(10);
        }
        Err(error) => {
            eprintln!("ERROR: Failed to create the socket: {error}");
            return ExitCode::FAILURE;
        }
    };

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
