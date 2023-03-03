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

pub fn open<S: AsRef<OsStr>>(url: &S) {
    let browser = match var_os("FIREURL_BROWSER") {
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
        .expect("Failed to spawn firefox");
}
