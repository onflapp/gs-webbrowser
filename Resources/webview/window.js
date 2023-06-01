window.addEventListener('message', function(evt) {
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
  window.mylasttitle = 0;
  window.mywebviewid = 'ASGGFD-webview-'+window.location.hash.substr(1);

  document.title = window.mywebviewid;

  wv.addEventListener('loadstart', function(evt) {
    sendCommand('ON_LOADING_START:'+evt.url);
  });
  wv.addEventListener('loadstop', function(evt) {
    var u = window.mywebview.getAttribute('src');
    u = u?u:'';
    if (u.indexOf(window.myfileserver) === 0) {
      u = 'file://'+u.substr(window.myfileserver.length);
    }
    sendCommand('ON_LOADING_STOP:'+u);
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
    else {
      evt.request.allow();
    }
    evt.preventDefault();
    console.log(evt);
  });
  wv.addEventListener('contentload', function(evt) {
    if (window.mylasttitle === 0) {
      checkTitle();
    }
  /* try to avoid injecting any code into the website
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
  */
  });

  sendCommand('ON_READY:'+window.mywebviewid);

});

function checkTitle() {
  var cb = function(rv) {
    var newtitle = ''+(rv?rv:'');
    if (window.mylasttitle !== newtitle) {
      window.mylasttitle = newtitle;
      sendCommand('ON_TITLE:'+newtitle);
    }
  };
  try {
    window.mywebview.executeScript({ code:'window.document.title' }, cb);
  }
  catch(ex) {
  }

  setTimeout(checkTitle, 1000);
}

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
    if (val.indexOf('file://') == 0) {
      var s = val.substr(7);
      var i = s.indexOf('/');
      var p = s.substr(0, i);
      var f = s.substr(i);
      var h = 'http://localhost:'+p;
      window.myfileserver = h;
      window.mywebview.setAttribute('src', h+f);
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
  'CUT': function(val) {
    window.mywebview.executeScript({code:'document.execCommand("cut")'});
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
