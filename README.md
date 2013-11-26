Vex Robot iPhone Drive
===================

Drive a VEX robot from an iPhone!

How It Works:
===== 

1. The Rasberry Pi creates a Wifi network from a Vex Robot
2. The iPhone connects and sends acceleromter data to the Pi
3. The Pi forwards the data to the Vex Cortex through its serial port
4. The Vex Cortex recieves the data and controls the motors


Requirements:
===== 
- Rasberry Pi
 - [Arch Linux] (https://www.archlinux.org/download/)
 - [PySerial] (http://pyserial.sourceforge.net/) (*Linux*: "pacman install python2-pyserial")
 - [Hostapd] (http://hostap.epitest.fi/hostapd/) (*Linux*:  "pacman install hostapd")

- iPhone
 - [Cocos2D 2.1] (http://www.cocos2d-iphone.org/) *included*
 - [CocoaAsyncUdpSocket] (https://github.com/robbiehanson/CocoaAsyncSocket) *included*

- Vex Cortex
 - [EasyC v4] (http://www.intelitekdownloads.com/easyCV4/)

- Compatible Wirless Adapter


Note: Use a static IP address on the iPhone to connect it to the Pi's Wifi Network
