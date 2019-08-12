
let menuItems = [
  { label: 'Home', link: 'index.html' },
  { label: 'Settings', link: 'usersettings.html', groups: ['admin'] },
  { label: 'Network', link: 'network.html', groups: ['admin'] },
  { label: 'Logout', link: 'logout.html' }
];

function showErrors (errors) {
  errors.forEach(function (error) {
    $('#errors').append(error + '<br>');
  });
}

function clearErrors () {
  $('#errors').html('');
}

function showMessages (messages) {
  messages.forEach(function (message) {
    $('#messages').append(message + '<br>');
  });
}

function clearMessages () {
  $('#messages').html('');
}

function clearAll () {
  clearMessages();
  clearErrors();
}


function showMenu (groups) {
  menuItems.forEach(function (item) {
    if (!item.groups || item.groups.filter(function (group) { return groups.includes(group); }).length) {
      $('#menu').append('<a href="' + item.link + '">' + item.label + '</a>');
    }
  });
}


function showSecured (groups) {
  groups.forEach(function (group) {
    $('.group-' + group).removeClass('secured');
  });
}


function getSetting (setting, callback) {
  apiCall('GET', 'setting/' + setting, null, callback);
}

function setSetting (setting, value, callback) {
  apiCall('POST', 'setting/' + setting, value, callback);
}

function apiCall (method, path, data, callback) {
  $.ajax({
    url: 'api/' + path,
    dataType: 'json',
    type: method,
    contentType: 'application/json',
    data: (data ? JSON.stringify(data) : null),
    headers: { 'Accept': 'application/json', 'Content-Type': 'application/json' }
  })
  .done(function (response) {
    if (response) {
      if (response.error) {
        showErrors([response.error]);
      }
      if (response.message) {
        showMessages([response.message]);
      }
    }
    if (callback) {
      callback(response);
    }
  })
  .fail(function (jqXHR, textStatus, errorThrown) {
    showErrors(['API call failure']);
  });
}

function getQueryVariable(variable) {
  var query = window.location.search.substring(1);
  var vars = query.split('&');
  for (var i = 0; i < vars.length; i++) {
    var pair = vars[i].split('=');
    if (decodeURIComponent(pair[0]) == variable) {
      return decodeURIComponent(pair[1]);
    }
  }
  return null;
}
