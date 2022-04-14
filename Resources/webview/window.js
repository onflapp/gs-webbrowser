window.addEventListener('message', function(evt) {
  receiveCommand(evt.data);
});

window.addEventListener('click', function(evt) {
  sendCommand('ON_FOCUS:');
});

window.addEventListener('load', function(evt) {
  var wv = document.getElementById('main');
  window.mywebview = wv;
  window.mywebviewid = 'ASGGFD-webview-'+window.location.hash.substr(1);

  document.title = window.mywebviewid;

  wv.addEventListener('loadstart', function(evt) {
    sendCommand('ON_LOADING_START:'+evt.url);
  });
  wv.addEventListener('loadstop', function(evt) {
    var u = window.mywebview.getAttribute('src');
    sendCommand('ON_LOADING_STOP:'+(u?u:''));
  });
  wv.addEventListener('contentload', function(evt) {
  });
  wv.addEventListener('newwindow', function(evt) {
    console.log(evt);
  });
  wv.addEventListener('permissionrequest', function(evt) {
    if (evt.permission === 'download') {
      evt.request.allow();
    }
    console.log(evt);
  });

  sendCommand('ON_READY:'+window.mywebviewid);
});

function receiveCommand(cmd) {
  console.log('received:' + cmd);
  var i = cmd.indexOf(':');
  var nm = null;
  var val = null;

  if (i > 0) {
    nm = cmd.substr(0, i);
    val = cmd.substr(i+1);
  }
  else {
    nm = cmd;
  }

  if (nm) {
    var f = CMD[nm];
    if (f) f(val);
  }
}

function sendCommand(cmd) {
  chrome.runtime.sendMessage(cmd);
}

CMD = {
  'LOAD': function(val) {
    window.mywebview.setAttribute('src', val);
  },
  'BACK': function(val) {
    window.mywebview.back();
  },
  'FORWARD': function(val) {
    window.mywebview.forward();
  },
  'RELOAD': function(val) {
    window.mywebview.reload();
  }
};
