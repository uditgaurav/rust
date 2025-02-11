use libc::{c_int, sockaddr, socklen_t};
use lazy_static::lazy_static;
use regex::Regex;
use std::ffi::CStr;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::net::{IpAddr, SocketAddr};
use std::os::raw::c_char;
use std::str::FromStr;

lazy_static! {
    static ref BLOCKED_HOSTS: Vec<(String, u16)> = {
        let mut blocked = Vec::new();
        if let Ok(file) = File::open("/tmp/chaos_blocked_hosts.txt") {
            let reader = BufReader::new(file);
            for line in reader.lines() {
                if let Ok(line) = line {
                    let parts: Vec<&str> = line.splitn(2, ':').collect();
                    if parts.len() == 2 {
                        let host = parts[0].to_string();
                        let port = parts[1].parse::<u16>().unwrap_or(0);
                        blocked.push((host, port));
                    }
                }
            }
        }
        blocked
    };
    static ref HOST_PORT_REGEX: Regex = Regex::new(r"^(.+?)(:(\d+))?$").unwrap();
}

#[no_mangle]
pub extern "C" fn getaddrinfo(
    node: *const c_char,
    service: *const c_char,
    hints: *const libc::addrinfo,
    res: *mut *mut libc::addrinfo,
) -> c_int {
    let original_getaddrinfo: extern "C" fn(
        *const c_char,
        *const c_char,
        *const libc::addrinfo,
        *mut *mut libc::addrinfo,
    ) -> c_int = unsafe {
        std::mem::transmute(libc::dlsym(
            libc::RTLD_NEXT,
            b"getaddrinfo\0".as_ptr() as *const _,
        ))
    };

    let hostname = unsafe { CStr::from_ptr(node) }.to_str().unwrap_or("");
    let service_name = unsafe { CStr::from_ptr(service) }.to_str().unwrap_or("");

    for (blocked_host, blocked_port) in BLOCKED_HOSTS.iter() {
        if hostname == *blocked_host {
            if *blocked_port == 0 || service_name == blocked_port.to_string() {
                unsafe {
                    *libc::__errno_location() = libc::EAI_FAIL;
                }
                return libc::EAI_FAIL;
            }
        }
    }

    original_getaddrinfo(node, service, hints, res)
}

#[no_mangle]
pub extern "C" fn connect(sockfd: c_int, addr: *const sockaddr, addrlen: socklen_t) -> c_int {
    let original_connect: extern "C" fn(c_int, *const sockaddr, socklen_t) -> c_int = unsafe {
        std::mem::transmute(libc::dlsym(
            libc::RTLD_NEXT,
            b"connect\0".as_ptr() as *const _,
        ))
    };

    if addr.is_null() {
        return original_connect(sockfd, addr, addrlen);
    }

    let sa_family = unsafe { (*addr).sa_family };
    let sock_addr = match sa_family as i32 {
        libc::AF_INET => {
            let addr = unsafe { &*(addr as *const libc::sockaddr_in) };
            SocketAddr::from((addr.sin_addr.s_addr.to_ne_bytes(), addr.sin_port))
        }
        libc::AF_INET6 => {
            let addr = unsafe { &*(addr as *const libc::sockaddr_in6) };
            SocketAddr::from((addr.sin6_addr.s6_addr, addr.sin6_port))
        }
        _ => return original_connect(sockfd, addr, addrlen),
    };

    let ip = sock_addr.ip();
    let port = sock_addr.port();

    for (blocked_host, blocked_port) in BLOCKED_HOSTS.iter() {
        if let Ok(blocked_ip) = IpAddr::from_str(blocked_host) {
            if blocked_ip == ip && (*blocked_port == 0 || *blocked_port == port) {
                unsafe {
                    *libc::__errno_location() = libc::ECONNREFUSED;
                }
                return -1;
            }
        }
    }

    original_connect(sockfd, addr, addrlen)
}
