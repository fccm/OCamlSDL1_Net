open Sdlnet

let () =
  let port =
    try int_of_string Sys.argv.(1)
    with _ ->
      Printf.eprintf "Usage: %s port\n" Sys.argv.(0);
      exit 1
  in
  Sdlnet.init ();
  let sd = Sdlnet.udp_open port in
  let p = Sdlnet.alloc_packet 512 in
  let rec loop () =
    match Sdlnet.udp_recv sd p with
    | None -> loop ()
    | Some p ->
        Printf.printf "UDP Packet incoming\n";
        Printf.printf "\tChan:    %d\n" p.channel;
        Printf.printf "\tData: %d '%s'\n" (String.length p.data) p.data;
        Printf.printf "\tMaxlen:  %d\n" p.maxlen;
        Printf.printf "\tStatus:  %d\n" p.status;
        Printf.printf "\tAddress: %lX %X\n" p.address_host p.address_port;
        Printf.printf "%!";
        if p.data <> "quit" then loop ()
  in
  loop ();
  Sdlnet.free_packet p;
  Sdlnet.quit ();
;;
