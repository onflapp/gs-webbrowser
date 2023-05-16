#import "Document.h"

@implementation Document(scripting)

- (void) loadPage:(NSString*) url {
  NSURL* u = [NSURL URLWithString:url];
  if (u) {
    [self setURL:u];
  }
}

- (NSString*) executeJavaScript:(NSString*) js {
  return [webView executeJavaScript:js];
}

@end
