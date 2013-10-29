import serial
import random
import time
import socket
import threading
import SocketServer
import platform
import subprocess
import sys
import os


#if linksys wifi adapter is not plugged in
if not "Linksys" in subprocess.check_output('lsusb',shell=True):
    sys.path.insert(0, '/root/python')
    __import__("pi uart dump")
    exit()


port = serial.Serial("/dev/ttyAMA0", baudrate=115200, timeout=3.0)



Acc=1
Hb=2
clientStatus={}

class ThreadedUDPRequestHandler(SocketServer.BaseRequestHandler):

    def handle(self):
        clientAddr=self.client_address[0]
        data = self.request[0]
        
        if data=='stop':
            #stop motors
            #precalculated checksum (255) and the stop byte for each side
            #send twice just in case it fails once
            port.write((chr(255)+(chr(127)*2))*2)
            print 'stopping motors'

            if clientAddr in clientStatus:
                # del clientStatus[clientAddr]

                #still send hb messages to client
                clientStatus[clientAddr]=Hb

                print clientAddr,'stopped'
            else:
                print clientAddr,'stopped but was not connected'

            #tell client stop was ok
            self.request[1].sendto("stop ok", self.client_address)
            return

        if data=='shutdown':
            print 'stopping motors'
            port.write((chr(255)+(chr(127)*2))*2)

            print 'shutting down'
            subprocess.call(["shutdown", "0"])

        if ord(data[0])==90 and len(data)==1:
                #heartbeat msg
                port.write(chr(90))
                print 'heartbeat msg'
                return


        if data=='start Acc':

            clientStatus[clientAddr]=Acc

            return

        elif data=='start Hb':

            clientStatus[clientAddr]=Hb

            return



        if clientAddr in clientStatus:


            #valid packet values:
            #90 = heartbeat message, tells robot connection is still alive
            #c,x,y = main data message,(checksum,x tilt,y tilt)


            if clientStatus[clientAddr]==Acc:

                if ord(data[0])&128 and len(data)==3:
                    #checksum checking

                    #convert data(string) to array of ints
                    data=[ord(i) for i in data]

                    if data[0]!=(data[1]&25)|(data[2]&102)|128:
                        print self.client_address[0],'sent bad checksum data=',data,'checksum should be=',(data[0]&25)|(data[1]&102)|128
                        #bad sum
                        return


                    #forward data to serial port
                    port.write(''.join([chr(i) for i in data]))

                else:
                    print self.client_address[0],'sent bad packet len=',len(data),'data=',[ord(i) for i in data]
                    return


        else:
            

            print "recieved unknown packet",data,'from ip',clientAddr,'not connected'

                    

class ThreadedUDPServer(SocketServer.ThreadingMixIn, SocketServer.UDPServer):
    pass


#waits for wifi to start up and obtain a ip address
def waitForWifi():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    while 42:
        sockport='192.168.0.100'
        try:

            #try to connect to some other ip
            s.connect((sockport, 9999))

            #if wifi is up, this will be current ip address
            currentIp=s.getsockname()[0]

            #then close the connection
            s.close()
            print 'current ip:',currentIp
            # return '192.168.1.92'
            return currentIp
        except:
            print 'ERROR:could not open socket to ',sockport,'!'

        #wait before trying again
        time.sleep(1)







#local server stuff
PORT =  9999

#make a UDP server
server = ThreadedUDPServer((waitForWifi(), PORT), ThreadedUDPRequestHandler)

#and put it in a thread
server_thread = threading.Thread(target=server.serve_forever)

server_thread.daemon = True
server_thread.start()


sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

while 1:
    #read input from robot, and forward any heartbeat messages to clients
    char=port.read(1)
    

    if len(char)==1 and ord(char)==90:
        print 'sending hb msg to ',clientStatus
        for addr in clientStatus:
            sock.sendto(chr(90), (addr, PORT))

   



server.shutdown()