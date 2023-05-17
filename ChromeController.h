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
  BOOL running;
}

- (void) ensureChromeControllerIsReady:(ChromeControllerDelegate*) del;
- (void) stopTrying;

@end

#endif // _CHROMECONTROLLER_H_
