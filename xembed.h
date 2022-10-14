#ifndef _XEMBED_H
#define _XEMBED_H

#include <X11/Xlib.h> 

/* XEMBED messages */
#define XEMBED_EMBEDDED_NOTIFY          0
#define XEMBED_WINDOW_ACTIVATE          1
#define XEMBED_WINDOW_DEACTIVATE        2
#define XEMBED_REQUEST_FOCUS            3
#define XEMBED_FOCUS_IN                 4
#define XEMBED_FOCUS_OUT                5
#define XEMBED_FOCUS_NEXT               6
#define XEMBED_FOCUS_PREV               7
/* 8-9 were used for XEMBED_GRAB_KEY/XEMBED_UNGRAB_KEY */
#define XEMBED_MODALITY_ON              10
#define XEMBED_MODALITY_OFF             11
#define XEMBED_REGISTER_ACCELERATOR     12
#define XEMBED_UNREGISTER_ACCELERATOR   13
#define XEMBED_ACTIVATE_ACCELERATOR     14

#define WM_IGNORE_FOCUS_EVENTS "WM_IGNORE_FOCUS_EVENTS"

/* Details for  XEMBED_FOCUS_IN: */
#define XEMBED_FOCUS_CURRENT            0
#define XEMBED_FOCUS_FIRST              1
#define XEMBED_FOCUS_LAST               2

extern int sendxembed(Display* dpy, Window win, long msg, long detail, long d1, long d2);
extern int sendclientmsg(Display* dpy, Window win, Atom msg, long value);

#endif
