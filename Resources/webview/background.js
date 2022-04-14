chrome.app.runtime.onLaunched.addListener(function(evt) {
  var nm = evt.items[0].entry.name;
  var a = nm.split('.');
  window.myport = Number.parseInt(a[0]);

  chrome.app.window.create('window.html#'+window.myport, {
    innerBounds: {
      width: 1,
      height: 1
    }
  }, 
  function(win) {
    window.myappwindow = win;
    console.log('started');
    connectController();
  });
});

chrome.runtime.onMessage.addListener(function(msg, sender, reponse) {
  console.log('message:' + msg);
  sendCommand(msg);
  return true;
});

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

function connectController() {
  var buffer = '';

  chrome.sockets.tcp.create({}, function(createInfo) {
    chrome.sockets.tcp.connect(createInfo.socketId, 'localhost', window.myport, function() {
      console.log('connected');
      window.mysocketid = createInfo.socketId;
    });
  });
  chrome.sockets.tcp.onReceive.addListener(function(info) {
    if (info.socketId != window.mysocketid) return;
    var v = ab2str(info.data);
    buffer += v;

    var i = buffer.indexOf('\n');
    while (i > 0) {
      var s = buffer.substr(0, i);
      receiveCommand(s);
      buffer = buffer.substr(i+1);
      i = buffer.indexOf('\n');
    }
  });
  chrome.sockets.tcp.onReceiveError.addListener(function(info) {
    console.log(info);
  });
}

function receiveCommand(cmd) {
  console.log('received: ' + cmd);
  var win = window.myappwindow.contentWindow;
  win.postMessage(cmd);
}

function sendCommand(cmd) {
  var buff = str2ab(cmd+'\n');
  chrome.sockets.tcp.send(window.mysocketid, buff, function(ex) {
    console.log('sent');
  });
}
