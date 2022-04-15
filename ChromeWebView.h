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
  ChromeController* chromeController;
  BOOL ready;
  NSURL* initialURL;
}

- (void) setDelegate:(id) del;
- (id) delegate;

- (void) loadURL:(NSURL*) url;

- (void) stopLoading:(id) sender;
- (void) goBack:(id) sender;
- (void) goForward:(id) sender;

@end

#endif
