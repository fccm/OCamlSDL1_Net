(** OCamlSDL1_Net: ocaml bindings for the SDL_net library *)
(*
  Copyright (C) 2012 Florent Monnier <monnier.florent __ gmail>
 
  This software is provided "AS-IS", without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.
 
  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, without restrictions.
*)

type uint16 = int

(** The SDL_net library is a cross-platform network library for use with SDL *)

external init : unit -> unit = "ml_SDLNet_Init"
external quit : unit -> unit = "ml_SDLNet_Quit"

external linked_version : unit -> int * int * int = "ml_SDLNet_Linked_Version"
external compile_version : unit -> int * int * int = "ml_SDL_NET_VERSION"

(** {3 UDP} *)

type udp_socket

external udp_open : port:uint16 -> udp_socket = "ml_SDLNet_UDP_Open"
external udp_close : sock:udp_socket -> unit = "ml_SDLNet_UDP_Close"

type udp_packet

external alloc_packet : size:int -> udp_packet = "ml_SDLNet_AllocPacket"
external free_packet : packet:udp_packet -> unit = "ml_SDLNet_FreePacket"

type udp_packet_contents = {
  channel: int;   (* The src/dst channel of the packet *)
  data: string;   (* The packet data *)
  maxlen: int;    (* The size of the data buffer *)
  status: int;    (* packet status after sending *)
  address_host: int32;
                  (* The source/dest address of an incoming/outgoing packet *)
  address_port: int;
}

external udp_recv :
  sock:udp_socket -> packet:udp_packet -> udp_packet_contents option
  = "ml_SDLNet_UDP_Recv"

external udp_packet_set_address :
  packet:udp_packet -> host:int * int * int * int -> port:int -> unit
  = "ml_UDPpacket_set_address"

external udp_packet_set_data :
  packet:udp_packet -> data:string -> unit
  = "ml_UDPpacket_set_data"

external udp_packet_get_len : packet:udp_packet -> int
  = "ml_UDPpacket_get_len"

external udp_packet_get_maxlen : packet:udp_packet -> int
  = "ml_UDPpacket_get_maxlen"

external get_max_udp_channels : unit -> int
  = "ml_get_SDLNet_Max_UDPChannels"

external get_max_udp_addresses : unit -> int
  = "ml_get_SDLNet_Max_UDPAddresses"

external udp_send : sock:udp_socket -> channel:int -> packet:udp_packet -> int
  = "ml_SDLNet_UDP_Send"

external udp_unbind : sock:udp_socket -> channel:int -> unit
  = "ml_SDLNet_UDP_Unbind"

(** {3 IP} *)

type ip_address =  {
  host: int * int * int * int;
  port: int;
}

external resolve_host : host:string -> port:int -> ip_address
  = "ml_SDLNet_ResolveHost"

external resolve_ip : ip_address -> string
  = "ml_SDLNet_ResolveIP"

(** {3 TCP} *)

type tcp_socket

external tcp_open : ip_address -> tcp_socket
  = "ml_SDLNet_TCP_Open"

external tcp_accept : server:tcp_socket -> tcp_socket
  = "ml_SDLNet_TCP_Accept"

external get_peer_address : tcp_socket -> ip_address
  = "ml_SDLNet_TCP_GetPeerAddress"

external tcp_send : sock:tcp_socket -> data:string -> int
  = "ml_SDLNet_TCP_Send"

external tcp_send_sub :
  sock:tcp_socket -> data:string -> ofs:int -> len:int -> int
  = "ml_SDLNet_TCP_Send"

external tcp_recv : sock:tcp_socket -> data:string -> int
  = "ml_SDLNet_TCP_Recv"

external tcp_recv_sub :
  sock:tcp_socket -> data:string -> ofs:int -> maxlen:int -> int
  = "ml_SDLNet_TCP_Recv_sub"

external tcp_close : tcp_socket -> unit
  = "ml_SDLNet_TCP_Close"

(** {3 Socket-Set} *)

type socket_set

external alloc_socket_set :
  maxsockets:int -> socket_set
  = "ml_SDLNet_AllocSocketSet"

external tcp_add_socket : set:socket_set -> sock:tcp_socket -> unit
  = "ml_SDLNet_TCP_AddSocket"

external udp_add_socket : set:socket_set -> sock:udp_socket -> unit
  = "ml_SDLNet_UDP_AddSocket"

external tcp_del_socket : set:socket_set -> sock:tcp_socket -> unit
  = "ml_SDLNet_TCP_DelSocket"

external udp_del_socket : set:socket_set -> sock:udp_socket -> unit
  = "ml_SDLNet_UDP_DelSocket"

external check_sockets : set:socket_set -> timeout:int -> int
  = "ml_SDLNet_CheckSockets"
