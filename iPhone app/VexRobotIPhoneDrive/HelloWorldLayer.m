//
//  HelloWorldLayer.m
//  VexRobotIPhoneDrive
//
//  Created by Ryan on 6/5/13.
//  Copyright __MyCompanyName__ 2013. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import <SystemConfiguration/CaptiveNetwork.h>

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}




// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
        
        //cocos2d stuff
		// ask director for screen width
		screenSize =[[CCDirector sharedDirector] view].frame.size;//568 if iphone5;480 if iphone4
		
		// Default font size will be 28 points.
		[CCMenuItemFont setFontSize:28];
        
        self.touchEnabled = YES;
        
        [UIAccelerometer sharedAccelerometer].updateInterval=kAccUpdateInvetval;
        
        
        
        //ip address text box
        ipAddress = [[UITextField alloc] initWithFrame:CGRectMake(screenSize.width/2+64, 20, 128, 30)];
        [ipAddress setDelegate:self];
        [ipAddress setText:@"192.168.0.1"];
        [ipAddress setTextColor: [UIColor colorWithRed:255 green:255 blue:255 alpha:1.0]];
        ipAddress.textAlignment = UITextAlignmentCenter;
        [[[CCDirector sharedDirector] view] addSubview:ipAddress];
        
        
        //wifi name
        wifiName = [[UITextField alloc] initWithFrame:CGRectMake(screenSize.width/2-128-64, 20, 128, 30)];
        [wifiName setDelegate:self];
        wifiName.enabled=NO;        
        [wifiName setText:[NSString stringWithFormat:@"Wifi: %@",[self fetchSSIDInfo]]];
        [wifiName setTextColor: [UIColor colorWithRed:255 green:255 blue:255 alpha:1.0]];
        wifiName.textAlignment = UITextAlignmentLeft;
        [[[CCDirector sharedDirector] view] addSubview:wifiName];
        
        
        //sensitivity Slider
        sensitivitySlider=[[UISlider alloc] initWithFrame:CGRectMake(15, 52, screenSize.width-30, 22)];
        [[[CCDirector sharedDirector] view] addSubview:sensitivitySlider];
      
        //default vars
        xstart=0;
        ystart=0;
        callibrateNextFire=NO;
        sensitivitySlider.value=1;
        currentCircleIsRed=YES;
        
        
        lastReceivedHeartbeat=[[NSDate alloc] init];
        drawnode=[CCDrawNode node];
        [self addChild:drawnode];
        
#ifdef SHOW_DOT
        //red
        [drawnode drawDot:dotLocation radius:10 color:ccc4f(1, 0, 0, 1)];
#endif        
        [self schedule:@selector(update)];
        
        //asyncSocket setup
        asyncSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
       
        
        
        //refresh wifi name on re entry
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateWifi) name:@"AppActive" object:nil];
        
        
        //connect
        [self connectAndStartHeartbeat:YES];
        
        
        
        //menu items
        CCMenuItem *start = [CCMenuItemFont itemWithString:@"start" block:^(id sender) {
			
            //does not reconnect if already connected
            [self connectAndStartHeartbeat:YES];
            
            //start sending accelerometer data
            [asyncSocket sendData:[@"start Acc" dataUsingEncoding:NSUTF8StringEncoding]  withTimeout :kTimeout tag:0];
            self.accelerometerEnabled=YES;
		}];
        
        
        
        CCMenuItem *stop = [CCMenuItemFont itemWithString:@"stop" block:^(id sender) {
            
			//stop sending accelerometer data
            self.accelerometerEnabled=NO;
            [asyncSocket sendData:[@"stop" dataUsingEncoding:NSUTF8StringEncoding]  withTimeout :kTimeout tag:0];
			
            
           
		}];
        
      
        
        
        CCMenuItem *shutdown = [CCMenuItemFont itemWithString:@"shutdown" block:^(id sender) {
            
            [self connectAndStartHeartbeat:NO];
            
            [asyncSocket sendData:[@"shutdown" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:kTimeout tag:0];
            
            [asyncSocket close];
		}];
        
        CCMenuItem *callibrate = [CCMenuItemFont itemWithString:@"callibrate" block:^(id sender) {
			callibrateNextFire=YES;
            AccWasOn=self.accelerometerEnabled;
            self.accelerometerEnabled=YES;
            
		}];
        

        //menus
		CCMenu *startstopmenu = [CCMenu menuWithItems:start,stop,nil];
        CCMenu *othermenu=[CCMenu menuWithItems:callibrate,shutdown,nil];
		
        
		[startstopmenu alignItemsVerticallyWithPadding:10.0f];
		[startstopmenu setPosition:ccp( 20+50, screenSize.height/2 - 50)];
        
        
		[othermenu alignItemsInColumns:@2,nil];
		[othermenu setPosition:ccp( screenSize.width/2, screenSize.height/2+70)];
		
        
		// Add the menu to the layer
		[self addChild:startstopmenu];
		[self addChild:othermenu];

	}
	return self;
}


#pragma mark -
#pragma mark GCDAsyncUdpSocket Methods

- (void)socket:(GCDAsyncUdpSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	dlog(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
	
}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    
    dlog(@"recieved %@",data);
    
    //if it is heartbeat msg, update last heartbeat messge receive time
    if ([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] cStringUsingEncoding:NSUTF8StringEncoding][0]==90) {
        lastReceivedHeartbeat=[[NSDate alloc] init];
    }

}




-(void)connectAndStartHeartbeat:(BOOL)startHeartbeat{
    
    //connect
    if (!asyncSocket.isConnected) {
        
        
        //set up receiver data
        NSError *error = nil;
        if (![asyncSocket bindToPort:PORT error:&error])
        {
            dlog(@"ERROR: failed to bind to port %i error:%@",PORT,error);
        }
        
        if (![asyncSocket beginReceiving:&error])
        {
            dlog(@"ERROR: failed to start recieving data:%@",error);
        }
        
        
        
        dlog(@"Connecting to \"%@\" on port %i...", ipAddress.text, PORT);
        
        error = nil;
        if (![asyncSocket connectToHost:ipAddress.text onPort:PORT error:&error])
        {
            dlog(@"Error connecting: %@", error);
        }
    }
    
    if (startHeartbeat) {
        
        dlog(@"starting hb");
        
        [asyncSocket sendData:[@"start Hb" dataUsingEncoding:NSUTF8StringEncoding]  withTimeout :kTimeout tag:0];
        
        //start sending heartbeat msg
        [self schedule:@selector(onTimer) interval:0.25];
    }
    
}
-(void)onTimer{
    if (asyncSocket.isConnected) {
        
        [asyncSocket sendData:[@"Z" dataUsingEncoding:NSUTF8StringEncoding]  withTimeout :kTimeout tag:0];
        dlog(@"sent hb msg");
    }
    
    else{
        dlog(@"not sending hb msg");
    }
}





#pragma mark -
#pragma mark Accelerometer Methods



-(double)limitValue:(double)thevalue{
    if (thevalue>1) {
        return 1.0;
    }
    else if (thevalue<-1){
        return -1.0;
    }
    return thevalue;
}
- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
    dlog(@"xtilt=%f, ytilt=%f",acceleration.x,acceleration.y);
    
    //callibrate
    if (callibrateNextFire) {
        callibrateNextFire=NO;
        self.accelerometerEnabled=AccWasOn;
        AccWasOn=NO;
        xstart=acceleration.x;
        ystart=acceleration.y;
        return;
    }
    
    //account for callibration and sensitivity
    double xdelta=(acceleration.x-xstart);
    double ydelta=(acceleration.y-ystart);
    xdelta/=(sensitivitySlider.value+.001);
    ydelta/=(sensitivitySlider.value+.001);
    
    //compress data and make checksum
    unsigned char x=(unsigned char)(([self limitValue:xdelta]*127)+127);
    unsigned char y=(unsigned char)(([self limitValue:ydelta]*127)+127);
    unsigned char c=((x&25)|(y&102))|128;
    
    unsigned char array[3]={c,x,y};
    
    [asyncSocket sendData:[NSData dataWithBytes:&array length:sizeof(array)]  withTimeout :kTimeout tag:0];
}

#pragma mark -
#pragma mark Text Field Methods


-(BOOL)textFieldShouldReturn:(UITextField *)textField {

    //reset the socket
    [asyncSocket close];
    [self connectAndStartHeartbeat:YES];
    
    [ipAddress resignFirstResponder];
    return YES;
}
-(void)textFieldDidEndEditing: (UITextField *)textField {
    [ipAddress endEditing:YES];
    
}

#pragma mark -
#pragma mark Misc

-(void)update{
    
    //change to green circle if recieving heartbeat
    if ([lastReceivedHeartbeat timeIntervalSinceNow] * -1000.0<500) {
        
        if (currentCircleIsRed) {
            currentCircleIsRed=NO;
            [drawnode clear];
            
#ifdef SHOW_DOT
            //green
            [drawnode drawDot:dotLocation radius:10 color:ccc4f(0, 1, 0, 1)];
#endif
        }
        
        return;
        
    }
    else if (!currentCircleIsRed){
        
        currentCircleIsRed=YES;
        [drawnode clear];
        
#ifdef SHOW_DOT
        //red
        [drawnode drawDot:dotLocation radius:10 color:ccc4f(1, 0, 0, 1)];
#endif
        
    }
}

- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
    [asyncSocket setDelegate:nil];
    [asyncSocket close];
}
-(void)updateWifi{
    
    [wifiName setText:[NSString stringWithFormat:@"Wifi: %@",[self fetchSSIDInfo]]];
}
- (NSString *)fetchSSIDInfo
{
    NSArray *ifs = (id)CFBridgingRelease(CNCopySupportedInterfaces());
    NSDictionary * info = nil;
    for (NSString *ifnam in ifs) {
        info = (id)CFBridgingRelease(CNCopyCurrentNetworkInfo((CFStringRef)CFBridgingRetain(ifnam)));
        if (info && [info count]) {
            break;
        }
    }
    return [info objectForKey:@"SSID"];
}
@end
