#ifndef _PCAPPPROJ_CHROMEWEBVIEW_H
#define _PCAPPPROJ_CHROMEWEBVIEW_H

#import <AppKit/AppKit.h>
#import "ExternalWebView.h"
#import "ChromeController.h"

@protocol ChromeWebViewDelegate

- (void) webView:(id)webView didStartLoading:(NSURL*) url;
- (void) webView:(id)webView didFinishLoading:(NSURL*) url;
- (void) webView:(id)webView didChangeTitle:(NSString*) title;

@end

@interface ChromeWebView : ExternalWebView {
  IBOutlet id delegate;
  BOOL ready;
  NSURL* initialURL;
  NSURL* lastValidURL;
  NSString* __jsretval;

  CGFloat viewZoom;
}

- (void) setDelegate:(id) del;
- (id) delegate;

- (void) loadURL:(NSURL*) url;

- (NSString*) executeJavaScript:(NSString*) js;
- (void) stopLoading:(id) sender;
- (void) goBack:(id) sender;
- (void) goForward:(id) sender;
- (void) performZoomAction:(id) sender;
- (void) close;

@end

#endif
