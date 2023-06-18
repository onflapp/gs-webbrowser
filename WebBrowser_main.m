/* 
   Project: WebBrowser

   Author: root

   Created: 2020-07-22 12:15:43 +0300 by root
*/

#import <AppKit/AppKit.h>
#import "AppController.h"

static NSBundle* __my_main_bundle;

@interface NSBundle (Launcher)
+ (NSBundle*) mainBundle;
@end

@implementation NSBundle (Launcher)
+ (NSBundle*) mainBundle {
    return __my_main_bundle;
}
@end

int main(int argc, const char *argv[]) {
  char *bundle_env = getenv("MAIN_WEBBROWSER_BUNDLE");
  if (bundle_env != NULL) {
    NSString* apppath = [[NSString alloc] initWithCString:bundle_env];
    NSLog(@"loading MAIN_WEBBROWSER_BUNDLE from %@", apppath);
    __my_main_bundle = [NSBundle bundleWithPath:apppath];
  }
  else {
    NSString* apppath = [[[NSString alloc] initWithCString:argv[0]]stringByDeletingLastPathComponent];
    __my_main_bundle = [NSBundle bundleWithPath:apppath];
  }

  return NSApplicationMain(argc, argv);
}
