#![warn(rust_2018_idioms)]

use std::borrow::Cow;
use std::env::var_os;
use std::ffi::OsStr;
use std::fs::create_dir;
use std::path::PathBuf;
use std::process::Command;

pub mod utils;

pub fn socket_path() -> PathBuf {
    let mut path = PathBuf::from(var_os("XDG_RUNTIME_DIR").expect("XDG_RUNTIME_DIR not set"));
    path.push("fireurl/fireurl0");
    create_dir(path.parent().unwrap())
        .or_else(utils::filter_already_exists)
        .expect("Failed to create $XDG_RUNTIME_DIR/fireurl.");
    path
}

/// Checks that `uri` complies to certain restrictions.
///
/// - Only ASCII graphic character are allowed (! to ~)
///   TODO: Could be stricter
/// - Must be at least 3 characters long
/// - Starts with an letter
/// - Has a colon within the first 15 characters and all preceding characters
///   must be letters, digits, `+`, `-` or `.`.
pub fn is_uri_trustworthy(uri: &str) -> bool {
    uri.chars().all(|c| c.is_ascii_graphic())
        && uri.len() >= 3
        && uri.bytes().next().unwrap().is_ascii_alphabetic()
        && uri
            .bytes()
            .take(15)
            .take_while(|b| b.is_ascii_alphanumeric() || [b'+', b'-', b':', b'.'].contains(b))
            .any(|b| b == b':')
}

pub fn open<S: AsRef<OsStr>>(url: &S, env_name: &str) {
    let browser = match var_os(env_name) {
        Some(browser) => Cow::Owned(browser),
        None => Cow::Borrowed(OsStr::new("firefox")),
    };
    // TODO:
    //  - Make program and commandline configurable.
    //  - Collect zombies
    //  - What happens if we start a new main instance outside of a session?
    //  - Support non http(s) urls
    Command::new(browser)
        .arg(url.as_ref())
        .spawn()
        .expect("Failed to spawn browser");
}
