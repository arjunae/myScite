// tcp tunnel over ssh

extern crate ssh2; // see http://alexcrichton.com/ssh2-rs/

use std::io::Read;
use std::io::Write;
use std::str;
use std::net;

fn main() {
  // establish SSH session with remote host
  println!("Connecting to host...");
  // substitute appropriate value for IPv4
  let tcp = net::TcpStream::connect("<IPv4>:22").unwrap();
  let mut session = ssh2::Session::new().unwrap();
  session.handshake(&tcp).unwrap();
  // substitute appropriate values for username and password
  // session.userauth_password("<username>", "<password>").unwrap();
  assert!(session.authenticated());
  println!("SSH session authenticated.");

  // start listening for TCP connections
  let listener = net::TcpListener::bind("localhost:5000").unwrap();
  println!("Started listening, ready to accept");
  for stream in listener.incoming() {
    println!("===============================================================================");

    // read the incoming request
    let mut stream = stream.unwrap();
    let mut request = vec![0; 8192];
    let read_bytes = stream.read(&mut request).unwrap();
    println!("REQUEST ({} BYTES):\n{}", read_bytes, str::from_utf8(&request).unwrap());

    // send the incoming request over ssh on to the remote localhost and port
    // where an HTTP server is listening
    let mut channel = session.channel_direct_tcpip("localhost", 8080, None).unwrap();
    channel.write(&request).unwrap();

    // read the remote server's response (all of it, for simplicity's sake)
    // and forward it to the local TCP connection's stream
    let mut response = Vec::new();
    let read_bytes = channel.read_to_end(&mut response).unwrap();
    stream.write(&response).unwrap();
    println!("SENT {} BYTES AS RESPONSE", read_bytes);
