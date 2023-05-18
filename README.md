# WebBrowser

WebBrowser.app is based on Google Chrome and specifically created for [GNUstep Desktop](https://github.com/onflapp/gs-desktop/tree/main).

It uses XEmbedding + Chrome extensions API to accomplish its goal.
One huge advantage of this approach is that it uses Google's own binary, 
which means no compromises!

It will play Netflix or let you log into your Google account without complaining.
Yet, you'll get full GNUstep experience.

- GNUstep UI with proper menus
- pasteboard integration
- services
- scripting using StepTalk

### Prerequisites

As the app is just a wrapper, it obviously needs Chrome properly installed.
This can be done differently depending on what version or flavour of your Linux distro you are running.

To install Chrome manually (x64), you could do the following:

```
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome-stable_current_amd64.deb
````

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

### Future Direction

Although the browser is fully functional as of today, it still has many rough edges.

One very annoying thing is that it fails to capture the Chrome window on start up sometimes.
This is not a big problem as you can simply close the window and create new one, but it is annoying.

Improve how downloads are handled. As this functionality is not exposed by the Chrome extension API 
in any meaning way, I had to "hack" around it. I'll have to find a better way.

Drag & Drop support - this is mainly limited by how XDnd interacts with GNUsteps own drag & drop support. It will most likely require GNUstep backend code to be enhanced to make it work.

Improve the GUI. The current user interface is very basic, however as it is all GNUstep, new functionality should be easy to add.
