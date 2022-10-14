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
  XSync(dpy, False);
  return 1;
}

int sendclientmsg(Display* dpy, Window win, Atom msg, long value) {
	XEvent event;

	event.xclient.type = ClientMessage;
	event.xclient.message_type = msg;
	event.xclient.format = 32;
	event.xclient.display = dpy;
	event.xclient.window = win;
	event.xclient.data.l[0] = value;
	event.xclient.data.l[1] = 0;
	event.xclient.data.l[2] = 0;
	event.xclient.data.l[3] = 0;
	XSendEvent(dpy, win, True, EnterWindowMask, &event);
	XSync(dpy, False);
  return 1;
}
