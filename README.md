# WebBrowser

WebBrowser.app is _based on Google Chrome_ and specifically created for [GNUstep Desktop](https://github.com/onflapp/gs-desktop/tree/main).

It uses XEmbedding + Chrome extension API to accomplish its goal.
One huge advantage of this approach is that it uses Google's own binary, 
which means no compromises!

It will play Netflix or let you log into your Google account without complaining.
Yet, you'll get full GNUstep experience.

- GNUstep UI with proper menus
- pasteboard integration
- services
- scripting using StepTalk

### Prerequisites

WebBrowser.app relies on GS Desktop to work properly, using it as stand-alone application is probably not going to work.

As the app is just a wrapper, it obviously needs Chrome properly installed.
This can be done differently depending on what version or flavour of your Linux distro you are running.

#### Manual Install Chrome (x64)

do the following:

```
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome-stable_current_amd64.deb
````

#### Manual Install Chrome (Ubuntu)

do the following:

```
apt install chrome-browser
```

As long as the app can find one of the following binaries, you should be fine.

```
google-chrome
chromium
chromium-browser
chrome
```

WebBrowser.app relies on [Chrome extension API](https://developer.chrome.com/docs/extensions/reference/) 
and on Chrome's ability to load extensions as web-apps (`--load-and-launch-app`).
This functionality might get removed from Chrome as it has been marked as deprecated, but so far so good.

### How does it work

#### event flow

```
ExternalWebView                  Chrome App                                      Web page
command --- socket --> background.js --- post message --> window.js --- API --> webview tag
event   <-- socket --- background.js <-- post message --- window.js <-- API --- webview tag
```

#### initialization

1. ChromeController starts chrome process (Resources/webview/start.sh)
   Chrome tends to create background process that is reused, this makes it a bit messy.
   The script creates empty pid file and waits for it to contain port of the Chrome app.

2. The start.sh uses `--load-and-launch-app` to load Chrome app declared in manifest.json.

3. The Chrome app (background.js) starts local socket server.
   It writes its port into the pid file.

4. ChromeController pickups the port number and connects to it.
   It delegates connection to the ExternalWebView

5. ExternalWebView will connect to the background.js and starts conversation.
   New connection will create new Chrome Window (window.js).
   Once new Chrome Window appears, it is captured by ExternalWebView and reparented into its own view.

6. ExternalWebView issues commands that will be passed to the window.js. 
   Like load page and also listens for events coming back.

### Future Direction

Although the browser is fully functional as of today, it still has many rough edges.

Improve how downloads are handled. As this functionality is not exposed by the Chrome extension API 
in any meaning way, I had to "hack" around it. I'll have to find a better way.

Drag & Drop support - this is mainly limited by how XDnd interacts with GNUsteps own drag & drop support. It will most likely require GNUstep backend code to be enhanced to make it work.

Improve the GUI. The current user interface is very basic, however as it is all GNUstep, new functionality should be easy to add.
