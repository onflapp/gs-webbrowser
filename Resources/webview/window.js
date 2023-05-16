window.addEventListener('message', function(evt) {
  debugger;
  if (evt.origin.indexOf('chrome-extension://') == 0) {
    receiveCommand(evt.data);
  }
  else {
    sendCommand(evt.data);
  }
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
  wv.addEventListener('message', function(evt) {
    console.log(evt);
  });
  wv.addEventListener('newwindow', function(evt) {
    sendCommand('ON_NEW_WINDOW:'+evt.targetUrl);
    evt.preventDefault();
  });
  wv.addEventListener('permissionrequest', function(evt) {
    if (evt.permission === 'download') {
      sendCommand('ON_DOWNLOAD:'+evt.request.url);
      evt.request.allow();
    }
    console.log(evt);
  });
  wv.addEventListener('contentload', function(evt) {
    this.executeScript({
      code: 
      'window.addEventListener("message", function(e) {' +
        'if (e.data == "init") {' +
          'window.addEventListener("mouseup", function(evt) { ' +
            'if (evt.button > 0 && evt.target.tagName === "A") {' +
              'console.log(evt);' +
              'e.source.postMessage("ON_LINK_INFO:"+evt.target.href, "*"); ' +
            '}' +
          '});' +
          'e.source.postMessage("ON_TITLE:"+window.document.title, "*"); ' +
        '}' +
      '})'
    });
    setTimeout(function() {
        wv.contentWindow.postMessage('init', '*');
    },200);
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
    if (val.indexOf('file:///') == 0) {
      window.mywebview.setAttribute('src', 'http://localhost:2222' + val.substr(7));
    }
    else {
      window.mywebview.setAttribute('src', val);
    }
  },
  'BACK': function(val) {
    window.mywebview.back();
  },
  'FORWARD': function(val) {
    window.mywebview.forward();
  },
  'RELOAD': function(val) {
    window.mywebview.reload();
  },
  'ZOOM': function(val) {
    window.mywebview.setZoom(Number.parseFloat(val));
  },
  'COPY': function(val) {
    window.mywebview.executeScript({code:'document.execCommand("copy")'});
  },
  'PASTE': function(val) {
    window.mywebview.executeScript({code:'document.execCommand("paste")'});
  },
  'SELECTALL': function(val) {
    window.mywebview.executeScript({code:'document.execCommand("selectall")'});
  },
  'FINDNEXT': function(val) {
    window.mywebview.find(val);
  },
  'FINDPREV': function(val) {
    window.mywebview.find(val, {backward:true});
  },
  'EXEC': function(val) {
    var code = unescape(val);    
    var cb = function(rv) {
      sendCommand('ON_RETURN:'+escape(rv));
    };
    window.mywebview.executeScript({ code:code }, cb);
  }
};
