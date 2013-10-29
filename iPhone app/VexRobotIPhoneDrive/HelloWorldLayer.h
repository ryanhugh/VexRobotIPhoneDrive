//
//  HelloWorldLayer.h
//  VexRobotIPhoneDrive
//
//  Created by Ryan on 6/5/13.
//  Copyright __MyCompanyName__ 2013. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "GCDAsyncUdpSocket.h"
#import "Macros.h"

CGSize screenSize;

// HelloWorldLayer
@interface HelloWorldLayer : CCLayerColor <UITextFieldDelegate,GCDAsyncUdpSocketDelegate>
{
    GCDAsyncUdpSocket *asyncSocket;
    UITextField *ipAddress,*wifiName;
    UISlider * sensitivitySlider;
    double ystart,xstart;
    BOOL callibrateNextFire,AccWasOn;
    CCTimer *myTimer;
    NSDate *lastReceivedHeartbeat;
    
    CCDrawNode * drawnode;
    BOOL currentCircleIsRed;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

-(double)limitValue:(double)thevalue;
-(void)onTimer;
-(void)updateWifi;
-(void)connectAndStartHeartbeat:(BOOL)startHeartbeat;
-(void)update;
@end
