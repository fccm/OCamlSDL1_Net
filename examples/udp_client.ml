open Sdlnet

let () =
  let host, port =
    try (Sys.argv.(1), int_of_string Sys.argv.(2))
    with _ ->
      Printf.eprintf "Usage: %s host port\n" Sys.argv.(0);
      exit 1
  in
  Sdlnet.init ();

  (* Open a socket on random port *)
  let sd = Sdlnet.udp_open 0 in

  (* Resolve server name  *)
  let ip = Sdlnet.resolve_host host port in

  begin
    let a, b, c, d = ip.host in
    Printf.printf " host: %d.%d.%d.%d\n" a b c d;
    Printf.printf " port: %d\n" ip.port;
    Printf.printf "%!";
  end;

  let p = Sdlnet.alloc_packet 512 in

  let rec loop () =
    print_endline "Input some text:";
    let data = read_line () in
    Sdlnet.udp_packet_set_data p data;
    
    (* Set the destination host and destination port *)
    Sdlnet.udp_packet_set_address p ip.host ip.port;

    let _ = Sdlnet.udp_send sd (-1) p in

    if data <> "quit" then loop ()
  in
  loop ();
  Sdlnet.free_packet p;
  Sdlnet.quit ();
;;
