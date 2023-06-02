var DEBUG = 0;
var PORT = 0;

chrome.app.runtime.onLaunched.addListener(function(evt) {
  var hide = DEBUG?false:true;
  window.mypidfile = evt.items[0].entry;
  chrome.app.window.create('info.html', {
    hidden:hide,
    innerBounds: {
      width: 200,
      height: 200
    }
  }, function(win) {
    window.mydebugwin = win;
    setTimeout(function() {
      startServer(PORT);
    }, 500);
  });
});

/*
chrome.runtime.onSuspend.addListener(function(evt) {
  window.mypidfile.remove(function(rv) {
  });
});
*/

function DataConnection(sockId) {
  var that = this;
  this.buffer = '';
  this.clientSocketId = sockId;
  this.receiveData = function(data) {
    var v = ab2str(data);
    that.buffer += v;

    var i = that.buffer.indexOf('\n');
    while (i > 0) {
      var s = that.buffer.substr(0, i);
      that.receiveCommand(s);
      that.buffer = that.buffer.substr(i+1);
      i = that.buffer.indexOf('\n');
    }
  };

  this.receiveCommand = function(cmd) {
    console.log('received: ' + cmd);
    if (cmd == 'TERMINATE:') {
      var wins = chrome.app.window.getAll();
      for (var i = 0; i < wins.length; i++) {
        wins[i].close();
      }
    }
    else if (cmd == 'SHOW_DEBUG:') {
      if (window['mydebugwin']) {
        window.mydebugwin.show();
      }
    }
    else {
      var cw = that.win.contentWindow;
      cw.postMessage(cmd);
    }
  };

  this.sendCommand = function(cmd) {
    var buff = str2ab(cmd+'\n');
    chrome.sockets.tcp.send(that.clientSocketId, buff, function(ex) {
      console.log('sent');
    });
  };
}

function startServer(port) {
  connections = {};

  chrome.sockets.tcpServer.onAccept.addListener(function(evt) {
    var con = new DataConnection(evt.clientSocketId);
    connections['x'+evt.clientSocketId] = con;
    createWindow(con);
  });

  chrome.sockets.tcp.onReceive.addListener(function(info) {
    var con = connections['x'+info.socketId];
    if (con) {
      con.receiveData(info.data);
    }
  });

  chrome.sockets.tcp.onReceiveError.addListener(function(info) {
    var sock = info.socketId;
    var con = connections['x'+sock];
    if (con) {
      con.win.close();
      delete connections['x'+sock];
    }
      
    console.log('error:' + info);
  });

  chrome.sockets.tcpServer.create({}, function(info) {
    chrome.sockets.tcpServer.listen(info.socketId, '127.0.0.1', port, function(result) {
      console.log(info);
      chrome.sockets.tcpServer.getInfo(info.socketId, function(r) {
        window.myport = r.localPort;
        console.log('listen:' + window.myport);
	window.mypidfile.createWriter(function(w) {
          waitForIO(w, function() {
            var b = new Blob([''+window.myport+'\n'], {type:'text/plain'});
            w.write(b);
	  });
	});
      });
   });
  });

  chrome.runtime.onMessage.addListener(function(msg, sender, reponse) {
    console.log('message:' + msg);
    var i = sender.url.indexOf('#');
    if (i > 0) {
      var wid = 'x'+sender.url.substr(i+1);
      var con = connections[wid];
      if (con) {
        con.sendCommand(msg);
      }
    }
    return true;
  });
}

function createWindow(con) {
  var x = -10;
  var y = -10;
  var w = 5;
  var h = 5;
  if (DEBUG) {
    x = 100;
    y = 100;
    w = 300;
    h = 300;
  }
  chrome.app.window.create('window.html#'+con.clientSocketId, {
    innerBounds: {
      left: x,
      top: y,
      width: w,
      height: h
    }
  }, 
  function(win) {
    console.log('started');
    con.win = win;
    chrome.sockets.tcp.setPaused(con.clientSocketId, false);
  });
}

function ab2str(buf) {
  return String.fromCharCode.apply(null, new Uint8Array(buf));
}

function str2ab(str) {
  var buf = new ArrayBuffer(str.length);
  var bufView = new Uint8Array(buf);
  for (var i=0, strLen=str.length; i < strLen; i++) {
    bufView[i] = str.charCodeAt(i);
  }
  return buf;
}

function waitForIO(writer, callback) {
  // set a watchdog to avoid eventual locking:
  var start = Date.now();
  // wait for a few seconds
  var reentrant = function() {
    if (writer.readyState===writer.WRITING && Date.now()-start<4000) {
      setTimeout(reentrant, 100);
      return;
    }
    if (writer.readyState===writer.WRITING) {
      console.error("Write operation is taking too long, aborting!"+
        " (current writer readyState is "+writer.readyState+")");
      writer.abort();
    } 
    else {
      callback();
    }
  };
  setTimeout(reentrant, 100);
}
