
let error = char_of_int 0xff
let timeout = 5000  (* five seconds *)

let udp_func sock f channel out in_ delay expect _timeout =
  let t = Sdltimer.get_ticks() in
  let rec loop() =
    let t2 = Sdltimer.get_ticks() in
    if t2 - t > _timeout then begin
      Printf.printf "timed out\n";
      (0)
    end else begin
      f sock channel out;
      match Sdlnet.udp_recv sock in_ with
      | None -> Sdltimer.delay delay; loop()
      | Some in_ ->
          if in_.data.[0] <> expect && in_.data.[0] <> error
          then loop()
          else begin
            if in_.data.[0] = error then
              Printf.printf "received error code\n";
            (if in_.data.[0] = error then -1 else 1)
          end
    end
  in
  loop()

let udpsend sock channel out in_ delay expect _timeout =
  udp_func sock Sdlnet.udp_send channel out in_ delay expect _timeout

let udprecv sock in_ delay expect _timeout =
  udp_func sock (fun _ () () -> ()) () () in_ delay expect _timeout

int main(int argc, char **argv)
{
  const char *host=NULL;
  char fname[65535];
  int plen, err=0;
  Sint32 flen;
  Uint16 port;
  Uint32 ipnum,ack;
  IPaddress ip;
  UDPpacket *out, *in, **packets, *outs[32];
  Sint32 p,p2,i;
  
  (* check our commandline *)
  let argc = Array.length Sys.argv in
  if argc < 2 then begin
    Printf.printf "%s port [packet-len]\n" Sys.argv.(0);
    exit 0;
  end;
  
  Sdl.init 0;
  Sdlnet.init();

  (* get the port from the commandline *)
  let port = int_of_string Sys.argv.(1) in
  if port = 0 then begin
    Printf.printf "a server port cannot be 0.\n";
    exit 3;
  end;
  
  let len =
    if argc > 2
    then int_of_string Sys.argv.(2)
    else 1400
  in
  
  (* open udp server socket *)
  let sock = Sdlnet.udp_open port in
  Printf.printf "port %hd opened\n" port;

  (* allocate max packet *)
  let out = Sdlnet.alloc_packet 65535 in
  let in_ = Sdlnet.alloc_packet 65535 in

  (* allocate 32 packets of size len *)
  packets = SDLNet_AllocPacketV(32, len);
  
  while true do
    Sdlnet.udp_unbind sock 0;
    in_->data[0]=0;
    print_endline "waiting...";
    let recv_loop () =
      match Sdlnet.udp_recv sock in_ with
      | None ->
          Sdltimer.delay 100;  (* 1/10th of a second *)
          recv_loop()
      | Some in_ -> in_
    in
    let in_c = recv_loop () in
    if in_c.data.[0] <> (char_of_int (1 lsl 4)) then
    begin
      in_.data.[0] <- error;
      in_->len=1;
      SDLNet_UDP_Send(sock, -1, in_);
      continue; /* not a request... */
    end;
    memcpy(&ip,&in_->address,sizeof(IPaddress));
    host = SDLNet_ResolveIP(&ip);
    ipnum = SDL_SwapBE32(ip.host);
    port = SDL_SwapBE16(ip.port);
    if (host)
      printf("request from host=%s port=%hd\n",host,port);
    else
      printf("request from host=%d.%d.%d.%d port=%hd\n",
          ipnum>>24,
          (ipnum>>16)&0xff,
          (ipnum>>8)&0xff,
          ipnum&0xff,
          port);
    if(SDLNet_UDP_Bind(sock, 0, &ip)==-1)
    {
      printf("SDLNet_UDP_Bind: %s\n",SDLNet_GetError());
      exit(7);
    }

    strcpy(fname,(char*)in_->data+1);
    printf("fname=%s\n",fname);
    
    /* get actual filesize */
    {
      struct stat buf;

#ifndef _MSC_VER
      if(stat(fname, &buf)>=0 && S_ISREG(buf.st_mode) && (f=fopen(fname,"rb")))
#else
      /* window MSVC version has no check for a valid file except that it opens */
      if(stat(fname, &buf)>=0 && (f=fopen(fname,"rb")))
#endif
        flen=buf.st_size;
      else
        flen=-1;
    }

    /* send filesize / expect ready */
    printf("sending filesize=%d blocksize=%d\n",flen,len);
    out->data[0]=1;
    SDLNet_Write32(flen,out->data+1);
    SDLNet_Write32(len-6,out->data+5);
    out->len=9;
    if (udpsend sock 0 out in_ 10 '\032' timeout) < 1 then
      continue;

    if(flen<0)
      continue; /* invalid file... */

    /* send file */
    printf("sending file\n");
    /*out->data[0]=2; */
    /*out->len=1; */
    /*SDLNet_UDP_Send(sock, -1, out); */

    plen=len-6;
    err=0;
    for(p=0;p<flen && !err;p+=32*plen)
    {
      while(SDLNet_UDP_Recv(sock, in_)); /* flush input */
      printf("p=%d\n",p);
      /* fill packets */
      for(p2=0;p+p2*plen<flen && p2<32;p2++)
      {
        packets[p2]->data[0]=2;
        packets[p2]->data[1]=p2;
        SDLNet_Write32(p+p2*plen,packets[p2]->data+2);
        packets[p2]->len=len;
        packets[p2]->channel=0;
        if (p+(p2+1)*plen>=flen) then
          packets[p2]->len=6+(flen-(p+p2*plen));
        if (!fread(packets[p2]->data+6, packets[p2]->len-6, 1, f)) then
        {
          perror("fread");
          continue; /* error on read */
        }
        outs[p2]=packets[p2];
      }
      
      /* setup the acks expected */
      ack=0;
      for(i=p2;i<32;i++)
        ack|=1<<i;

      /* send packets/expect ack */
      while(ack!=0xffffffff && !err)
      {
        do
        {
          printf("sending %d packets\n",p2);
          if(SDLNet_UDP_SendV(sock, outs, p2)<p2) then
          {
            printf("SDLNet_UDP_SendV: %s\n",SDLNet_GetError());
            err=-1;
            continue;
          }
          err = udprecv sock in_ 10 (3<<4) timeout;
        } while(err==1 && (Sint32) SDLNet_Read32(in_->data+1)!=p);
        if(err<1) then
        {
          err = 1;
          continue; (* we have an error... *)
        }
        err = 0;
        ack |= SDLNet_Read32(in_->data+5);
        printf("received ack 0x%08X\n",ack);
        for (p2=i=0; i<32; i++)
          if (!((ack>>i) & 1)) then
            outs[p2++]=packets[i];
      }
    }
    if(!err) then
      printf("done\n");
    else
      printf("finished with an error\n");

    fclose(f);
  done;
  
  (* close the socket *)
  Sdlnet.udp_close sock;
  
  (* free packet *)
  Sdlnet.free_packet out;
  Sdlnet.free_packet in_;
  (* SDLNet_FreePacketV(packets); *)
  
  Sdlnet.quit();
  Sdl.quit();
;;

