open Sdlnet

let () =
  let ip = resolve_host ~host:"127.0.0.1" ~port:0 in
  let b1, b2, b3, b4 = ip.host in
  Printf.printf "host: %d.%d.%d.%d\n" b1 b2 b3 b4;
  Printf.printf "port: %d\n" ip.port;
  let s = resolve_ip ip in
  Printf.printf "res: '%s'\n" s;
;;
