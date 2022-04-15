chrome.app.runtime.onLaunched.addListener(function(evt) {
  //var nm = evt.items[0].entry.name;
  chrome.app.window.create('info.html', {
    innerBounds: {
      width: 200,
      height: 200
    }
  });
  startServer(2222);
});

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
    var cw = that.win.contentWindow;
    cw.postMessage(cmd);
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
      
    console.log('error');
  });

  chrome.sockets.tcpServer.create({}, function(info) {
    chrome.sockets.tcpServer.listen(info.socketId, '127.0.0.1', port, function(result) {
      console.log('listen:' + result);
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
  var x = 100;
  var y = 100;
  var w = 300;
  var h = 300;
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


