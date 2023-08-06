#ifndef _CHROMECONTROLLER_H_
#define _CHROMECONTROLLER_H_

#import <AppKit/AppKit.h>
#import "LocalFileServer.h"

@interface ChromeControllerDelegate
- (void) chromeController:(id) controller isReady:(NSFileHandle*) fh;
@end

@interface ChromeController : NSObject {
  NSTask* task;
  NSString* pidfile;
  NSString* appname;
  BOOL running;
  NSMutableArray* delegates;
  id currentDelegate;
}

+ (ChromeController*) sharedInstance;
- (void) ensureChromeControllerIsReady:(ChromeControllerDelegate*) del;
- (NSInteger) fileServerPort;
- (void) showDebugWindow;
- (void) stopTrying;
- (void) closeProcess;

@end

#endif // _CHROMECONTROLLER_H_
