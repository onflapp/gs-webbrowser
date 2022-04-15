#ifndef _CHROMECONTROLLER_H_
#define _CHROMECONTROLLER_H_

#import <AppKit/AppKit.h>

@interface ChromeControllerDelegate
- (void) chromeController:(id) controller isReady:(NSFileHandle*) fh;
@end

@interface ChromeController : NSObject {
  NSString* pidfile;
}

- (void) ensureChromeControllerIsReady:(ChromeControllerDelegate*) del;

@end

#endif // _CHROMECONTROLLER_H_
