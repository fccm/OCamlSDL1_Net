/* OCamlSDL1_Net:
 OCaml bindings for SDL_net, a cross-platform network library for use with SDL1
 Copyright (C) 2012 Florent Monnier
 Contact: <monnier.florent __ gmail> s/__/@/
 
 This software is provided "AS-IS", without any express or implied
 warranty.  In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, without restrictions.
*/

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>

#include <SDL_net.h>

#include <string.h>

#define Val_none Val_int(0)

#define OCSDLNET_CHECK_UNSIGNEDNESS 1
#ifdef OCSDLNET_CHECK_UNSIGNEDNESS

static inline Uint16 Uint16_val(value v)
{
  long d = Long_val(v);
  if (d < 0 || d > 0xFFFF) caml_invalid_argument("uint16");
  return ((Uint16) d);
}

#else

#define Uint16_val(v) ((Uint16) Long_val(v))

#endif

#define Val_TCPsocket(tcpsock) ((value)(tcpsock))
#define TCPsocket_val(tcpsock) ((TCPsocket)(tcpsock))

#define Val_UDPsocket(udpsock) ((value)(udpsock))
#define UDPsocket_val(udpsock) ((UDPsocket)(udpsock))

#define Val_UDPpacket(packet) ((value)(packet))
#define UDPpacket_val(packet) ((UDPpacket *)(packet))

#define Val_SDLNet_SocketSet(sockset) ((value)(sockset))
#define SDLNet_SocketSet_val(sockset) ((SDLNet_SocketSet)(sockset))

static value
Val_some(value v)
{   
  CAMLparam1(v);
  CAMLlocal1(some);
  some = caml_alloc(1, 0);
  Store_field(some, 0, v);
  CAMLreturn(some);
}

CAMLprim value
ml_SDLNet_Init(value unit)
{
  if(SDLNet_Init() == -1) {
    caml_failwith(SDLNet_GetError());
  }
  return Val_unit;
}

CAMLprim value
ml_SDLNet_Quit(value unit)
{
  SDLNet_Quit();
  return Val_unit;
}

CAMLprim value
ml_SDLNet_Linked_Version(value unit)
{
  CAMLparam1(unit);
  CAMLlocal1(ver);

  const SDL_version *link_version = SDLNet_Linked_Version();

  ver = caml_alloc(3, 0);
  Store_field(ver, 0, Val_int(link_version->major));
  Store_field(ver, 1, Val_int(link_version->minor));
  Store_field(ver, 2, Val_int(link_version->patch));
  CAMLreturn(ver);
}

CAMLprim value
ml_SDL_NET_VERSION(value unit)
{
  CAMLparam1(unit);
  CAMLlocal1(ver);

  SDL_version compile_version;
  SDL_NET_VERSION(&compile_version);

  ver = caml_alloc(3, 0);
  Store_field(ver, 0, Val_int(compile_version.major));
  Store_field(ver, 1, Val_int(compile_version.minor));
  Store_field(ver, 2, Val_int(compile_version.patch));
  CAMLreturn(ver);
}

CAMLprim value
ml_SDLNet_UDP_Open(value port)
{
  UDPsocket udpsock;
  udpsock = SDLNet_UDP_Open(Uint16_val(port));
  if(!udpsock) {
    caml_failwith(SDLNet_GetError());
  }
  return Val_UDPsocket(udpsock);
}

CAMLprim value
ml_SDLNet_UDP_Close(value udpsock)
{
  SDLNet_UDP_Close(UDPsocket_val(udpsock));
  return Val_unit;
}

CAMLprim value
ml_SDLNet_AllocPacket(value size)
{
  UDPpacket *packet;
  packet = SDLNet_AllocPacket(Int_val(size));
  if (!packet) {
    caml_failwith(SDLNet_GetError());
  }
  return Val_UDPpacket(packet);
}

CAMLprim value 
ml_SDLNet_FreePacket(value packet)
{
  SDLNet_FreePacket(UDPpacket_val(packet));
  return Val_unit;
}

//int SDLNet_ResizePacket(UDPpacket *packet, int newsize);
//void SDLNet_UDP_SetPacketLoss(UDPsocket sock, int percent);

CAMLprim value
ml_UDPpacket_set_address(value packet, value host, value port)
{
  UDPpacket *p = UDPpacket_val(packet);
  Uint32 h;
  h =  ((Uint32) Long_val(Field(host, 0)));
  h |= ((Uint32) Long_val(Field(host, 1))) << 8;
  h |= ((Uint32) Long_val(Field(host, 2))) << 16;
  h |= ((Uint32) Long_val(Field(host, 3))) << 24;
  p->address.host = h;
  p->address.port = Int_val(port);
  return Val_unit;
}

CAMLprim value
ml_UDPpacket_set_data(value packet, value buf)
{
  UDPpacket *p = UDPpacket_val(packet);
  p->len = caml_string_length(buf) + 1;
  memcpy(p->data, String_val(buf), p->len);
  return Val_unit;
}

CAMLprim value
ml_UDPpacket_get_len(value packet)
{
  UDPpacket *p = UDPpacket_val(packet);
  return Val_int(p->len);
}

CAMLprim value
ml_UDPpacket_get_maxlen(value packet)
{
  UDPpacket *p = UDPpacket_val(packet);
  return Val_int(p->maxlen);
}

CAMLprim value
ml_get_SDLNet_Max_UDPChannels(value unit)
{
  return Val_int(SDLNET_MAX_UDPCHANNELS);
}

CAMLprim value
ml_get_SDLNet_Max_UDPAddresses(value unit)
{
  return Val_int(SDLNET_MAX_UDPADDRESSES);
}

CAMLprim value
ml_SDLNet_UDP_Recv(value sock, value packet)
{
  CAMLparam2(sock, packet);
  CAMLlocal3(res, pc, buf);

  UDPpacket *p = UDPpacket_val(packet);
  int ret = SDLNet_UDP_Recv(UDPsocket_val(sock), p);
  if (ret == -1) {
    caml_failwith(SDLNet_GetError());
  }
  if (ret == 0) {
    res = Val_none;
  }
  if (ret == 1) {
    pc = caml_alloc(6, 0);
    printf("len: %d\n", p->len);
    buf = caml_alloc_string(p->len-1);
    memcpy(String_val(buf), p->data, p->len-1);
    int i;
    for (i=0; i < p->len - 1; i++)
      printf(" %d", p->data[i]);
    printf("\n");
    fflush(stdout);

    Store_field(pc, 0, Val_int(p->channel));
    Store_field(pc, 1, buf);
    Store_field(pc, 2, Val_int(p->maxlen));
    Store_field(pc, 3, Val_int(p->status));
    Store_field(pc, 4, caml_copy_int32(p->address.host));
    Store_field(pc, 5, Val_int(p->address.port));

    res = Val_some(pc);
  }
  CAMLreturn(res);
}

CAMLprim value
ml_SDLNet_UDP_Send(value sock, value channel, value packet)
{
  int numsent = SDLNet_UDP_Send(
        UDPsocket_val(sock), Int_val(channel), UDPpacket_val(packet));
  if (!numsent) {
    caml_failwith(SDLNet_GetError());
  }
  return Val_int(numsent);
}

//int SDLNet_UDP_Bind(UDPsocket sock, int channel, const IPaddress *address);

CAMLprim value
ml_SDLNet_UDP_Unbind(value sock, value channel)
{
  SDLNet_UDP_Unbind((UDPsocket) sock, Int_val(channel));
  return Val_unit;
}

static value
value_of_IPaddress(IPaddress * address)
{
  CAMLparam0();
  CAMLlocal2(addr, h);

  h = caml_alloc(4, 0);

  Store_field(h, 0, Val_int((address->host & 0xFF)));
  Store_field(h, 1, Val_int((address->host >>  8) & 0xFF));
  Store_field(h, 2, Val_int((address->host >> 16) & 0xFF));
  Store_field(h, 3, Val_int((address->host >> 24) & 0xFF));

  addr = caml_alloc(2, 0);
  Store_field(addr, 0, h);
  Store_field(addr, 1, Val_int(address->port));
  CAMLreturn(addr);
}

CAMLprim value
ml_SDLNet_ResolveHost(value host, value port)
{
  IPaddress address;
  int ret = SDLNet_ResolveHost(&address, String_val(host), Int_val(port));
  if (ret == -1) {
    caml_failwith(SDLNet_GetError());
  }

  return value_of_IPaddress(&address);
}

static inline void
IPaddress_of_value(
    value ip_address,
    IPaddress *ip,
    const char *f_name)
{
  Uint32 h0, h1, h2, h3;

  value host = Field(ip_address, 0);
  value port = Field(ip_address, 1);

  h0 = (Uint32) Long_val(Field(host, 0));
  h1 = (Uint32) Long_val(Field(host, 1));
  h2 = (Uint32) Long_val(Field(host, 2));
  h3 = (Uint32) Long_val(Field(host, 3));

  if ((h0 | 0xFF) != 0xFF) caml_invalid_argument(f_name);
  if ((h1 | 0xFF) != 0xFF) caml_invalid_argument(f_name);
  if ((h2 | 0xFF) != 0xFF) caml_invalid_argument(f_name);
  if ((h3 | 0xFF) != 0xFF) caml_invalid_argument(f_name);

  ip->host = h0 | (h1 << 8) | (h2 << 16) | (h3 << 24);
  ip->port = Int_val(port);
}

CAMLprim value
ml_SDLNet_ResolveIP(value ip_addr)
{
  CAMLparam1(ip_addr);
  IPaddress ip;
  IPaddress_of_value(ip_addr, &ip, "Sdlnet.resolve_ip");

  const char *host = SDLNet_ResolveIP(&ip);

  CAMLreturn(caml_copy_string(host));
}

CAMLprim value
ml_SDLNet_TCP_Open(value ip_addr)
{
  IPaddress ip;
  IPaddress_of_value(ip_addr, &ip, "Sdlnet.tcp_open");
  TCPsocket sock = SDLNet_TCP_Open(&ip);
  return Val_TCPsocket(sock);
}

CAMLprim value
ml_SDLNet_TCP_Accept(value server)
{
  TCPsocket sock = SDLNet_TCP_Accept(TCPsocket_val(server));
  return Val_TCPsocket(sock);
}

CAMLprim value
ml_SDLNet_TCP_GetPeerAddress(value sock)
{
  IPaddress *ip = SDLNet_TCP_GetPeerAddress(TCPsocket_val(sock));
  if (ip == NULL) caml_failwith("Sdlnet.get_peer_address: server socket");
  return value_of_IPaddress(ip);
}

CAMLprim value
ml_SDLNet_TCP_Send(value sock, value data)
{
  int len = caml_string_length(data);
  int n = SDLNet_TCP_Send(TCPsocket_val(sock), String_val(data), len);
  return Val_int(n);
}

CAMLprim value
ml_SDLNet_TCP_Send_sub(value sock, value data, value _ofs, value _len)
{
  int ofs = Int_val(_ofs);
  int len = Int_val(_len);
  int size = caml_string_length(data);
  if (ofs < 0 || len <= 0 || ofs + len < size)
    caml_invalid_argument("Sdlnet.tcp_send_sub");
  int n = SDLNet_TCP_Send(TCPsocket_val(sock), String_val(data) + ofs, len);
  return Val_int(n);
}

CAMLprim value
ml_SDLNet_TCP_Recv(value sock, value data)
{
  int maxlen = caml_string_length(data);
  int n = SDLNet_TCP_Recv(TCPsocket_val(sock), String_val(data), maxlen);
  return Val_int(n);
}

CAMLprim value
ml_SDLNet_TCP_Recv_sub(value sock, value data, value _ofs, value _maxlen)
{
  int ofs = Int_val(_ofs);
  int maxlen = Int_val(_maxlen);
  int size = caml_string_length(data);
  if (ofs < 0 || maxlen <= 0 || ofs + maxlen < size)
    caml_invalid_argument("Sdlnet.tcp_recv_sub");
  int n = SDLNet_TCP_Recv(TCPsocket_val(sock), String_val(data), maxlen);
  return Val_int(n);
}

CAMLprim value
ml_SDLNet_TCP_Close(value sock)
{
  SDLNet_TCP_Close(TCPsocket_val(sock));
  return Val_unit;
}

/* Socket-Set */

CAMLprim value
ml_SDLNet_AllocSocketSet(value maxsockets)
{
  SDLNet_SocketSet sset = SDLNet_AllocSocketSet(Int_val(maxsockets));
  if (sset == NULL) caml_failwith("Sdlnet.alloc_socket_set");
  return Val_SDLNet_SocketSet(sset);
}

CAMLprim value
ml_SDLNet_TCP_AddSocket(value set, value sock)
{
  int r = SDLNet_TCP_AddSocket(SDLNet_SocketSet_val(set), TCPsocket_val(sock));
  if (r) caml_failwith("Sdlnet.tcp_add_socket");
  return Val_unit;
}

CAMLprim value
ml_SDLNet_UDP_AddSocket(value set, value sock)
{
  int r = SDLNet_UDP_AddSocket(SDLNet_SocketSet_val(set), UDPsocket_val(sock));
  if (r) caml_failwith("Sdlnet.udp_add_socket");
  return Val_unit;
}

CAMLprim value
ml_SDLNet_TCP_DelSocket(value set, value sock)
{
  int r = SDLNet_TCP_DelSocket(SDLNet_SocketSet_val(set), TCPsocket_val(sock));
  if (r) caml_failwith("Sdlnet.tcp_del_socket");
  return Val_unit;
}

CAMLprim value
ml_SDLNet_UDP_DelSocket(value set, value sock)
{
  int r = SDLNet_UDP_DelSocket(SDLNet_SocketSet_val(set), UDPsocket_val(sock));
  if (r) caml_failwith("Sdlnet.udp_del_socket");
  return Val_unit;
}

CAMLprim value
ml_SDLNet_CheckSockets(value set, value timeout)
{
  int n = SDLNet_CheckSockets(SDLNet_SocketSet_val(set), Int_val(timeout));
  if (n == -1) caml_failwith("Sdlnet.check_sockets");
  return Val_int(n);
}

/* ================================================ */
#if 0

typedef struct {
Uint32 host;            /* 32-bit IPv4 host address */
Uint16 port;            /* 16-bit protocol port */
} IPaddress;

/* Resolve a host name and port to an IP address in network form.
If the function succeeds, it will return 0.
If the host couldn't be resolved, the host portion of the returned
address will be INADDR_NONE, and the function will return -1.
If 'host' is NULL, the resolved host will be set to INADDR_ANY.
*/
#ifndef INADDR_ANY
#define INADDR_ANY      0x00000000
#endif
#ifndef INADDR_NONE
#define INADDR_NONE     0xFFFFFFFF
#endif
#ifndef INADDR_LOOPBACK
#define INADDR_LOOPBACK     0x7f000001
#endif
#ifndef INADDR_BROADCAST
#define INADDR_BROADCAST    0xFFFFFFFF
#endif
int SDLNet_ResolveHost(IPaddress *address, const char *host, Uint16 port);


int SDLNet_GetLocalAddresses(IPaddress *addresses, int maxcount);



typedef struct _UDPsocket *UDPsocket;
typedef struct {
int channel;        /* The src/dst channel of the packet */
Uint8 *data;        /* The packet data */
int len;            /* The length of the packet data */
int maxlen;         /* The size of the data buffer */
int status;         /* packet status after sending */
IPaddress address;  /* The source/dest address of an incoming/outgoing packet */
} UDPpacket;

/* Allocate/Free a UDP packet vector (array of packets) of 'howmany' packets,
each 'size' bytes long.
A pointer to the first packet in the array is returned, or NULL if the
function ran out of memory.
*/
UDPpacket ** SDLNet_AllocPacketV(int howmany, int size);
void SDLNet_FreePacketV(UDPpacket **packetV);




/* Get the primary IP address of the remote system associated with the 
socket and channel.  If the channel is -1, then the primary IP port
of the UDP socket is returned -- this is only meaningful for sockets
opened with a specific port.
If the channel is not bound and not -1, this function returns NULL.
*/
IPaddress * SDLNet_UDP_GetPeerAddress(UDPsocket sock, int channel);

/* Send a vector of packets to the the channels specified within the packet.
If the channel specified in the packet is -1, the packet will be sent to
the address in the 'src' member of the packet.
Each packet will be updated with the status of the packet after it has 
been sent, -1 if the packet send failed.
This function returns the number of packets sent.
*/
int SDLNet_UDP_SendV(UDPsocket sock, UDPpacket **packets, int npackets);

/* Send a single packet to the specified channel.
If the channel specified in the packet is -1, the packet will be sent to
the address in the 'src' member of the packet.
The packet will be updated with the status of the packet after it has
been sent.
This function returns 1 if the packet was sent, or 0 on error.

NOTE:
The maximum size of the packet is limited by the MTU (Maximum Transfer Unit)
of the transport medium.  It can be as low as 250 bytes for some PPP links,
and as high as 1500 bytes for ethernet.
*/

int SDLNet_UDP_RecvV(UDPsocket sock, UDPpacket **packets);



/* Any network socket can be safely cast to this socket type */
typedef struct _SDLNet_GenericSocket {
int ready;
} *SDLNet_GenericSocket;


int SDLNet_CheckSockets(SDLNet_SocketSet set, Uint32 timeout);

#define SDLNet_SocketReady(sock) \
        ((sock != NULL) && SDL_reinterpret_cast(SDLNet_GenericSocket, sock)->ready)

void SDLNet_FreeSocketSet(SDLNet_SocketSet set);


void SDLNet_Write16(Uint16 value, void *area);
void SDLNet_Write32(Uint32 value, void *area);

Uint16 SDLNet_Read16(void *area);
Uint32 SDLNet_Read32(void *area);

#define SDLNet_SetError SDL_SetError
#define SDLNet_GetError SDL_GetError

#define SDL_DATA_ALIGNED    1
#define SDL_DATA_ALIGNED    0
#define SDLNet_Write16(value, areap)    \
#define SDLNet_Write16(value, areap)    \
#define SDLNet_Write16(value, areap)    \
#define SDLNet_Write32(value, areap)    \

#define SDLNet_Read16(areap)        \
    (((SDL_reinterpret_cast(Uint8 *, areap))[1] <<  8) | (SDL_reinterpret_cast(Uint8 *, areap))[0] <<  0)

#define SDLNet_Read32(areap)        \
    (((SDL_reinterpret_cast(Uint8 *, areap))[3] << 24) | ((SDL_reinterpret_cast(Uint8 *, areap))[2] << 16) | \
     ((SDL_reinterpret_cast(Uint8 *, areap))[1] <<  8) |  (SDL_reinterpret_cast(Uint8 *, areap))[0] <<  0)

#endif
