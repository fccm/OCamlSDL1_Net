
let maxlen = (10 * 1024)  (* 10 KB - adequate for text! *)

let () =
  char message[MAXLEN];

  (* check our commandline *)
  if Array.length Sys.argv < 4
  then begin
    Printf.printf "%s host port username\n" Sys.argv.(0);
    exit 0;
  end;

  let name = Sys.argv.(3) in

  (* initialize SDL and SDL_net *)
  Sdl.init ();
  Sdlnet.init ();

  let set = Sdlnet.alloc_socket_set 1 in

  (* get the port from the commandline *)
  let port = int_of_string Sys.argv.(2) in

  (* Resolve the argument into an IPaddress type *)
  Printf.printf "Connecting to %s port %d\n" Sys.argv.(1) port;
  let ip = Sdlnet.resolve_host Sys.argv.(1) port in

  (* open the server socket *)
  let sock = Sdlnet.tcp_open ip in

  Sdlnet.tcp_add_socket set sock;

  (* login with a name *)
  Sdlnet.tcp_send sock name;

  Printf.printf "Logged in as %s\n" name;
  try
  while true do
    (* we poll keyboard every 1/10th of a second...simpler than threads *)
    (* this is fine for a text application *)
    
    (* wait on the socket for 1/10th of a second for data *)
    let numready = Sdlnet.check_sockets set 100 in

    (* check to see if the server sent us data *)
    if numready <> 0 && Sdlnet.socket_ready sock then
    begin
      (* getMsg is in tcputil.h, it gets a string from the socket *)
      (* with a bunch of error handling *)
      if (!getMsg(sock,&str))
        break;
      (* post it to the screen *)
      print_endline str;
    end;
    
    (* TODO *)

    (* set up the file descriptor set *)
    FD_ZERO(&fdset);
    FD_SET(fileno(stdin), &fdset);
    
    (* no waiting ;) *)
    memset(&tv, 0, sizeof(tv));
    
    (* check for keyboard input on stdin *)
    result = select(fileno(stdin)+1, &fdset, NULL, NULL, &tv);
    if (result == -1)
    {
      perror("select");
      break;
    }

    (* is there input? *)
    if (result && FD_ISSET(fileno(stdin), &fdset))
    {
      (* get the string from stdin *)
      if(!fgets(message,MAXLEN,stdin))
        break;

      (* strip the whitespace from the end of the line *)
      while(strlen(message) && strchr("\n\r\t ",message[strlen(message)-1]))
        message[strlen(message)-1] = '\000';

      (* if there was a message after stripping the end,  *)
      (* send it to the server *)
      if (strlen(message))
      {
        (*printf("Sending: %s\n",message); *)
        putMsg(sock,message);
      }
    }
  done
  with Exit ->
    (* shutdown SDL_net *)
    Sdlnet.quit ();

    (* shutdown SDL *)
    Sdl.quit ();
;;
