$(document).ready(function () {
  apiCall('GET', 'getsession', null, function (response) {
    showMenu(response.groups);
  });
});
