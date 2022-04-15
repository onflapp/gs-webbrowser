#import "ChromeController.h"

@implementation ChromeController

- (void) dealloc {
  [super dealloc];
}

- (void) startProcess {
  NSString* wp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"webview"];
  NSString* path = [wp stringByAppendingPathComponent:@"start.sh"];

  NSTask* task = [[NSTask alloc] init];
  [task setLaunchPath:@"/bin/sh"];
  [task setArguments:[NSArray arrayWithObjects:path, nil]];
  [task setCurrentDirectoryPath:wp];

  [task launch];
}

- (NSInteger) controllerPort {
  NSString* config = GSDefaultsRootForUser(nil);
  NSString* pidfile = [config stringByAppendingPathComponent:@"WebBrowser/controller.pid"];
  NSLog(@">>>> %@", pidfile);
  return 0;
}

@end
