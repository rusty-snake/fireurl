use std::io::{Error as IoError, ErrorKind as IoErrorKind, Result as IoResult};

pub fn filter_already_exists(error: IoError) -> IoResult<()> {
    if error.kind() == IoErrorKind::AlreadyExists {
        Ok(())
    } else {
        Err(error)
    }
}
