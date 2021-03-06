#import "ChromeController.h"

@implementation ChromeController

- (id) init {
  self = [super init];
  NSString* config = [NSStandardLibraryPaths() firstObject];
  
  running = YES;
  pidfile = [config stringByAppendingPathComponent:@"WebBrowser/controller.pid"];
  [pidfile retain];
  
  return self;
}

- (void) dealloc {
  [pidfile release];
  pidfile = nil;
  running = NO;

  [super dealloc];
}

- (void) ensureChromeControllerIsReady:(ChromeControllerDelegate*) del {
  if (!pidfile || !running) return;

  NSInteger p = [self processPort];
  if (p > 0) {
    NSLog(@"try to connect to %d", p);
    NSFileHandle* remote = [NSFileHandle fileHandleAsClientAtAddress:@"localhost" service:[NSString stringWithFormat:@"%ld", p] protocol:@"tcp"];
    if (remote) {
      NSLog(@"connected");
      [del chromeController:self isReady:remote];
    }
    else {
      NSLog(@"did not connect, try again");
      [self launchProcess];
      [self performSelector:@selector(ensureChromeControllerIsReady:) withObject: del afterDelay:1.0];
    }
  }
  else {
    [self launchProcess];
    NSLog(@"try again");
    [self performSelector:@selector(ensureChromeControllerIsReady:) withObject: del afterDelay:1.0];
  }
}

- (NSInteger) processPort {
  NSString* str = [NSString stringWithContentsOfFile:pidfile];
  NSLog(@">>>> %@ [%@]", pidfile, str);
  if (!str) return -1;
  else {
    return [str integerValue];
  } 
}

- (void) stopTrying {
  running = NO;
}

- (void) launchProcess {
  NSString* wp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"webview"];
  NSString* path = [wp stringByAppendingPathComponent:@"start.sh"];

  NSTask* task = [[NSTask alloc] init];
  [task setLaunchPath:@"/bin/bash"];
  [task setArguments:[NSArray arrayWithObjects:path, nil]];
  [task setCurrentDirectoryPath:wp];

  [task launch];
}

@end
