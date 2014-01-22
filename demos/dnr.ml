
let () =
  (* check our commandline *)
  let host =
    try Sys.argv.(1)
    with _ ->
      Printf.eprintf "%s host|ip\n" Sys.argv.(0);
      exit 0;
  in

  (* do a little version check for information *)
  begin
    let link_ver = Sdlnet.linked_version () in
    let comp_ver = Sdlnet.compile_version () in
    let print kind (major, minor, patch) =
      Printf.printf "%s with SDL_net version: %d.%d.%d\n"  kind major minor patch
    in
    print "compiled" comp_ver;
    print "running" link_ver;
  end;

  (*Sdl.init();*)

  Sdlnet.init();

  begin
    let localhostname = Unix.gethostname () in
    Printf.printf "Local Host: %s\n" localhostname;
    Printf.printf "Resolving %s\n" localhostname;
    let (h1, h2, h3, h4), _ = Sdlnet.resolve_host localhostname 0 in

    (* output the IP address nicely *)
    Printf.printf "Local IP Address : %d.%d.%d.%d\n" h1 h2 h3 h4;
  end;

  (* Resolve the argument into an IPaddress type *)
  Printf.printf "Resolving %s\n" host;
  let _host, _port = Sdlnet.resolve_host host 0 in

  let ip1, ip2, ip3, ip4 = _host in

  (* output the IP address nicely *)
  Printf.printf "IP Address : %d.%d.%d.%d\n" ip1 ip2 ip3 ip4;

  (* resolve the hostname for the IPaddress *)
  let host = Sdlnet.resolve_ip _host _port in

  if host <> ""
  then Printf.printf "Hostname   : %s\n" host
  else Printf.printf "No Hostname found\n";

  Sdlnet.quit();
  (*Sdl.quit();*)
;;

