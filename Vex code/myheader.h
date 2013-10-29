//serial port
#define kPortNumber 1



//base fuctions
void onTimer(void);
#define kHeartBeatTimer 1

void actualDriver(void);

#define isPressed(port) !GetDigitalInput(port)
int limitValue(int value);


// #define kShowDebug
#ifdef kShowDebug
#define dlog PrintToScreen
#define dlog(fmt, ...) PrintToScreen(("<%s@%d> " fmt), __PRETTY_FUNCTION__,__LINE__, ##__VA_ARGS__)
#else
#define dlog(...)
#endif


#define alog(fmt, ...) PrintToScreen(("<%s@%d> " fmt), __PRETTY_FUNCTION__,__LINE__, ##__VA_ARGS__)
