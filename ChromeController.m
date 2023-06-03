#import "ChromeController.h"

static LocalFileServer* fileServer = nil;
static ChromeController* chromeController = nil;

@implementation ChromeController

- (id) init {
  self = [super init];
  NSString* config = [NSStandardLibraryPaths() firstObject];
  appname = [[[[NSBundle mainBundle] bundlePath] lastPathComponent] stringByDeletingPathExtension];
  [appname retain];
  
  running = YES;
  pidfile = [config stringByAppendingPathComponent:appname];
  pidfile = [pidfile stringByAppendingPathComponent:@"controller.pid"];
  [pidfile retain];
  
  return self;
}

+ (ChromeController*) sharedInstance {
  if (!chromeController) chromeController = [[ChromeController alloc] init];
  return chromeController;
}

- (void) dealloc {
  chromeController = nil;

  [task release];
  task = nil;

  [appname release];
  appname = nil;

  [pidfile release];
  pidfile = nil;
  running = NO;

  NSLog(@"dealloc controller");
  [super dealloc];
}

- (void) ensureChromeControllerIsReady:(ChromeControllerDelegate*) del {
  if (fileServer == nil) {
    fileServer = [[LocalFileServer alloc] init];
    [fileServer start];
  }

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

- (NSInteger) fileServerPort {
  return [fileServer serverPort];
}

- (void) launchProcess {
  NSString* wp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"webview"];
  NSString* path = [wp stringByAppendingPathComponent:@"start.sh"];

  task = [[NSTask alloc] init];
  [task setLaunchPath:@"/bin/bash"];
  [task setArguments:[NSArray arrayWithObjects:path, appname, nil]];
  [task setCurrentDirectoryPath:wp];

  [[NSNotificationCenter defaultCenter]
	  addObserver:self
	     selector:@selector(taskDidTerminate:)
	         name:NSTaskDidTerminateNotification
	       object:task];

  [task launch];
}

- (void) taskDidTerminate:(NSNotification*) not {
  NSInteger rv = [task terminationStatus];
  NSLog(@"task has terminated %d", rv);

  if (rv == 10) {
	  NSRunAlertPanel(@"Unable to start the chrome process",@"Web Browser app expects to find one of these commands:\n google-chrome, chromium, chromium-browser or chrome",nil,nil,nil);
    running = NO;
  }

  [task release];
  task = nil;
}

- (void) sendCommand:(NSString*) cmd {
  if (!pidfile || !running) return;

  NSInteger p = [self processPort];
  if (p > 0) {
    NSFileHandle* remote = [NSFileHandle fileHandleAsClientAtAddress:@"localhost" service:[NSString stringWithFormat:@"%ld", p] protocol:@"tcp"];
    if (remote) {
      NSString* ss = [NSString stringWithFormat:@"%@\n", cmd];
      NSData* data = [ss dataUsingEncoding:NSUTF8StringEncoding];
      [remote writeData:data];
      [remote closeFile];
    }
  }

}

- (void) showDebugWindow {
  [self sendCommand:@"SHOW_DEBUG:"];
}

- (void) closeProcess {
  NSLog(@"terminate!");
  [self sendCommand:@"TERMINATE:"];
}

@end
