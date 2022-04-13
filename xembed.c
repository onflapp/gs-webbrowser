#include "xembed.h"

int sendxembed(Display* dpy, Window win, long msg, long detail, long d1, long d2) {
  XEvent e = { 0 };

  e.xclient.window = win;
  e.xclient.type = ClientMessage;
  e.xclient.message_type = XInternAtom(dpy, "_XEMBED", False);
  e.xclient.format = 32;
  e.xclient.data.l[0] = CurrentTime;
  e.xclient.data.l[1] = msg;
  e.xclient.data.l[2] = detail;
  e.xclient.data.l[3] = d1;
  e.xclient.data.l[4] = d2;
  XSendEvent(dpy, win, False, NoEventMask, &e);
  XFlush(dpy);
  return 1;
}


