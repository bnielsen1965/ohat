$(document).ready(function () {
  apiCall('GET', 'getsession', null, function (response) {
    showMenu(response.groups);
    getOTGSubnet();
    getWiFiMode();
    getGuestSettings();
    getHostSettings();
  });

  $('button#changeotgsubnet').on('click', changeOTGSubnet);
  $('button#changewifimode').on('click', setWiFiMode);
  $('button#changeguest').on('click', setGuestSettings);
  $('button#changehost').on('click', setHostSettings);
});


function getOTGSubnet () {
  apiCall('GET', 'getotgsubnet', null, function (response) {
    $('#otgsubnet').val(response.subnet);
  });
}

function changeOTGSubnet () {
  clearAll();
  // TODO do some checks, i.e. confirm, is page opened on USB network?
  apiCall('POST', 'setotgsubnet', { subnet: $('#otgsubnet').val() }, function (response) {
    if (response.success) {
      getOTGSubnet();
    }
  });
}


function getGuestSettings () {
  clearAll();
  getSetting('wifiguest', function (response) {
    $('#guestssid').val(response.value.ssid || '');
    $('#guestpsk').val(response.value.psk);
    $('#guestpskconfirm').val(response.value.psk);
  });
}

function setGuestSettings () {
  clearAll();
  if ($('#guestpsk').val() !== $('#guestpskconfirm').val()) {
    return showErrors(['Guest PSK and confirm PSK do not match']);
  }
  setSetting('wifiguest', { ssid: $('#guestssid').val(), psk: $('#guestpsk').val() }, function () {});
}


function getHostSettings () {
  clearAll();
  getSetting('wifihost', function (response) {
    $('#hostsubnet').val(response.value.subnet || '');
    $('#hostssid').val(response.value.ssid);
    $('#hostchannel').val(response.value.channel);
    $('#hostpsk').val(response.value.psk);
    $('#hostpskconfirm').val(response.value.psk);
  });
}

function setHostSettings () {
  clearAll();
  if ($('#hostpsk').val() !== $('#hostpskconfirm').val()) {
    return showErrors(['Host PSK and confirm PSK do not match']);
  }
  setSetting(
    'wifihost',
    {
      subnet: $('#hostsubnet').val(),
      ssid: $('#hostssid').val(),
      channel: $('#hostchannel').val(),
      psk: $('#hostpsk').val()
    },
    function () {}
  );
}


function getWiFiMode () {
  clearAll();
  getSetting('wifimode', function (response) {
    $('#wifimode').val(response.value.wifimode || '');
  });
}

function setWiFiMode () {
  clearAll();
  setSetting('wifimode', { wifimode: $('#wifimode').val() }, function () {
    // TODO use api to activate mode, i.e. call rfkill
  });
}
