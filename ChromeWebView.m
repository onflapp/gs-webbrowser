#import "ChromeWebView.h"
#import "FindPanel.h"
#import "DownloadPanel.h"
#import "DownloadStatusPanel.h"
#import "LinkPanel.h"
#include <X11/Xlib.h>

@implementation ChromeWebView

- (id) initWithFrame:(NSRect)r {
  self = [super initWithFrame:r];
  
  ChromeController* chromeController = [ChromeController sharedInstance];
  [chromeController ensureChromeControllerIsReady:self];

  viewZoom = [[NSUserDefaults standardUserDefaults] floatForKey: @"zoom_factor"];
  if (viewZoom < 0.2) viewZoom = 1.0;

  return self;
}

- (void) dealloc {
  [initialURL release];
  initialURL = nil;

  [lastValidURL release];
  lastValidURL = nil;

  [__jsretval release];
  __jsretval = nil;

  [super dealloc];
}

- (void) chromeController:(id) controller isReady:(NSFileHandle*) fh {
  [self connectController:fh];
}

- (void) destroyXWindow {
  [self close];
  ready = NO;

  [self disconnectController];
  [super destroyXWindow];
}

- (void) notifyXWindowEventsHasEnded {
  if (!closingwindow && ready) {
    NSLog(@"seems like we lost the webview");
  
    [delegate webView:self didChangeStatus:@"connection lost"];
    lastEvent = [[NSDate date]timeIntervalSince1970];
    [self performSelector:@selector(__checkIfStillHere) withObject:nil afterDelay:2.0];
  }
}

- (void) __checkIfStillHere {
  NSInteger dd = [[NSDate date]timeIntervalSince1970] - lastEvent;
  if (dd > 5) {
    [self reconnectAndReload];
  }
}

- (void) restartController {
  ChromeController* chromeController = [ChromeController sharedInstance];
  [chromeController ensureChromeControllerIsReady:self];
}

- (void) __sendConfig {
  NSMutableString* cfg = [NSMutableString string];
  float zoom = [[NSUserDefaults standardUserDefaults] floatForKey: @"zoom_factor"];
  float gsscale = [[NSUserDefaults standardUserDefaults] floatForKey: @"GSScaleFactor"];

  if (gsscale < 0.2) gsscale = 1.0;
  if (zoom < 0.2) zoom = 1.0;

  zoom = (zoom * gsscale);

  [cfg appendString:@"{"];
  [cfg appendFormat:@"\"zoom\":%f", zoom];
  [cfg appendString:@"}"];

  [self sendCommand:[NSString stringWithFormat:@"CONFIG:%@", cfg]];
}

- (void) __remapWebView:(NSString*) val {
  NSLog(@"ready: %@", val);
  Window w = [self findXWindowID:val];
  if (w) {
    [self remapXWindow:w];
    ready = YES;

    if (initialURL) {
      [self sendCommand:[NSString stringWithFormat:@"LOAD:%@", initialURL]];
      [initialURL release];
      initialURL = nil;
    }
  }
}

- (void) receiveCommand:(NSString*) cmd {
  NSRange r = [cmd rangeOfString:@":"];
  NSString* nm = [cmd substringToIndex:r.location];
  NSString* val = [cmd substringFromIndex:r.location+1];
  
  if ([nm isEqual:@"ON_READY"]) {
    [self __sendConfig];
    [self performSelector:@selector(__remapWebView:) withObject:val afterDelay:0.1];
  }
  if ([nm isEqual:@"ON_FOCUS"]) {
  }
  if ([nm isEqual:@"ON_RETURN"]) {
    [__jsretval release];

    __jsretval = [val stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [__jsretval retain];
  }
  if ([nm isEqual:@"ON_LOADING_START"]) {
    [delegate webView:self didStartLoading:[NSURL URLWithString:val]];
  }
  if ([nm isEqual:@"ON_LOADING_STOP"]) {
    NSURL* url = [NSURL URLWithString:val];
    [lastValidURL release];
    lastValidURL = [url retain];

    [delegate webView:self didFinishLoading:url];
  }
  if ([nm isEqual:@"ON_TITLE"]) {
    [delegate webView:self didChangeTitle:val];
  }
  if ([nm isEqual:@"ON_NEW_WINDOW"]) {
    [[NSApp delegate] application:NSApp openFile:val];
  }
  if ([nm isEqual:@"ON_LINK_INFO"]) {
    NSURL* url = [NSURL URLWithString:val];
    if (url) {
      [self showLinkInfo:url];
    }
  }
  if ([nm isEqual:@"ON_DOWNLOAD"]) {
    NSURL* url = [NSURL URLWithString:val];
    if (url) {
      NSLog(@"requested download %@", url);
      //[self requestDownload:url];
      [self followDownload:url];
    }
  }
}

- (void) showLinkInfo:(NSURL*) url {
  LinkPanel* link = [LinkPanel sharedInstance];
  [link showLinkInfo:url forWebView:self];
}

- (void) followDownload:(NSURL*) url {
  DownloadStatusPanel* download = [[DownloadStatusPanel alloc]initWithURL:url];
  NSWindow* win = [download window];
  //[[self window]addChildWindow:win ordered:NSWindowAbove];
  [win performSelector:@selector(orderFront:) withObject:self afterDelay:0.1];
}

- (void) requestDownload:(NSURL*) url {
  DownloadPanel* download = [[DownloadPanel alloc]initWithURL:url];
  NSWindow* win = [download window];
  //[[self window]addChildWindow:win ordered:NSWindowAbove];
  [win orderFront:self];
}

- (void) setDelegate:(id) del {
  delegate = del;
}

- (id) delegate {
  return delegate;
}

- (void) reconnectAndReload {
  [initialURL release];
  
  if (lastValidURL) initialURL = [lastValidURL retain];

  [delegate webView:self didChangeStatus:@"reconnecting..."];
  NSLog(@"reconnecting: %@", lastValidURL);

  [self restartController];
}

- (void) loadURL:(NSURL*) url {
  if (!url) return;

  if ([[url scheme]isEqualToString:@"file"]) {
    NSString* path = [[url description] substringFromIndex:7];
    NSInteger port = [[ChromeController sharedInstance] fileServerPort];
    NSString* u = [NSString stringWithFormat:@"file://%ld%@", port, path];
    url = [NSURL URLWithString:u];
  }

  if (ready) {
    if (xwindowid != 0) {
      [self sendCommand:[NSString stringWithFormat:@"LOAD:%@", url]];
    }
    else {
      NSLog(@"we lost our webview, reconnect");

      [initialURL release];
      initialURL = [url retain];

      [self restartController];
    }
  }
  else {
    [initialURL release];
    initialURL = [url retain];
  }
}

- (NSString*) executeJavaScript:(NSString*) js {
  if (!js) return nil;

  [__jsretval release];
  __jsretval = nil;

  NSString* code = [js stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  [self sendCommand:[NSString stringWithFormat:@"EXEC:%@", code]];

  for (NSInteger i = 0; i < 10; i++) {
    if (__jsretval) break;

    NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
    [[NSRunLoop currentRunLoop] runUntilDate: limit];
  }

  return __jsretval;
}

- (id)validRequestorForSendType:(NSString *)st
                     returnType:(NSString *)rt {
  if ([st isEqual:NSStringPboardType])
    return self;
  else
    return nil;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pb
                             types:(NSArray *)types
{
  NSString *sel = [[NSPasteboard pasteboardWithName:@"Selection"] stringForType:NSStringPboardType];

  if (sel) {
    [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pb setString:sel forType:NSStringPboardType];
    return YES;
  }
  else {
    return NO;
  }
}

- (void) syncPasteboard {
  /*
  NSString *sel = [[NSPasteboard pasteboardWithName:@"Selection"] stringForType:NSStringPboardType];
  if (sel) {
    NSPasteboard* pb = [NSPasteboard generalPasteboard];
    [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pb setString:sel forType:NSStringPboardType];
  }
  */
}

- (void) copy:(id)sender {
  [self sendCommand:@"COPY"];
  [self performSelector:@selector(syncPasteboard) withObject:nil afterDelay:0.3];
}

- (void) cut:(id)sender {
  [self sendCommand:@"CUT"];
  [self performSelector:@selector(syncPasteboard) withObject:nil afterDelay:0.3];
}

- (void) paste:(id)sender {
  [self sendCommand:@"PASTE"];
}

- (void) selectAll:(id)sender {
  [self sendCommand:@"SELECTALL"];
}

- (void) undo:(id)sender {
}

- (void) redo:(id)sender {
}

- (void) stopLoading:(id) sender {
}

- (void) goBack:(id) sender {
  [self sendCommand:@"BACK"];
}

- (void) goForward:(id) sender {
  [self sendCommand:@"FORWARD"];
}

- (void) performZoomAction:(id) sender {
  if ([sender tag] == 1) {
    viewZoom += 0.1;
    if (viewZoom > 2) viewZoom = 2;
  }
  else if ([sender tag] == -1) {
    viewZoom -= 0.1;
    if (viewZoom < 0.5) viewZoom = 0.5;
  }
  else {
    viewZoom = 1;
  }

  [[NSUserDefaults standardUserDefaults] setFloat:viewZoom forKey: @"zoom_factor"];

  float gsscale = [[NSUserDefaults standardUserDefaults] floatForKey: @"GSScaleFactor"];
  if (gsscale < 0.2) gsscale = 1.0;

  [self sendCommand:[NSString stringWithFormat:@"ZOOM:%f", (viewZoom*gsscale)]];
}

- (void) performFindPanelAction:(id) sender {
  FindPanel* panel = [FindPanel sharedInstance];
  if ([sender tag] == 1) {
    [panel orderFrontFindPanel:sender];
  }
  else if ([sender tag] == 2) {
    NSString* text = [panel findString];
    [self sendCommand:[NSString stringWithFormat:@"FINDNEXT:%@", text]];
  }
  else if ([sender tag] == 3) {
    NSString* text = [panel findString];
    [self sendCommand:[NSString stringWithFormat:@"FINDPREV:%@", text]];
  }
}

- (void) close {
  [self sendCommand:@"CLOSE:"];

  NSDate* limit = [NSDate dateWithTimeIntervalSinceNow:0.1];
  [[NSRunLoop currentRunLoop] runUntilDate: limit];
}

@end
