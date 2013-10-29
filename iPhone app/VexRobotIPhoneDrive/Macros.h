#import <Foundation/Foundation.h>

#ifdef DEBUG
#define _log( tttt, ... ) [NSString stringWithFormat:@"<%@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(tttt), ##__VA_ARGS__] ]

#define dlog( qqqq, ... ) NSLog(@"%@", _log(qqqq, ##__VA_ARGS__) )

#define elog( _s, ... ) NSLog(@"%@", _log(_s, ##__VA_ARGS__) );\
[[[UIAlertView alloc] initWithTitle:@"Error" message:_log(_s, ##__VA_ARGS__) delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil] show]

#define ifelog(__if__,_s, ...) if(__if__){elog(_s, ##__VA_ARGS__);}

#define elog2( s, ... ) dlog( s, ##__VA_ARGS__ )

#define dealloclog( s, ... ) dlog( s, ##__VA_ARGS__ )
#define dealloclog2( s, ... ) dlog( s, ##__VA_ARGS__ )

#else
#define dealloclog( s, ... )
#define dealloclog2( s, ... )
#define dlog( s, ... )
#define elog( s, ... )
#define elog2( s, ... )
#define ifelog(__if__,_s, ...)
#endif

#define PORT 9999

//data send timeout
#define kTimeout 0.05
#define kAccUpdateInvetval 1/20.0


#define dotLocation ccp(25,screenSize.height-25)


//#define SHOW_DOT