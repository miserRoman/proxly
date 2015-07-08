// Generated by CoffeeScript 1.8.0
var PopupCtrl, ProxlyCtrl, app, root,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

require('angular');

require('angular-sanitize');

require('angular-animate');

ProxlyCtrl = require('../../proxly-ctrl.coffee');

root = typeof exports !== "undefined" && exports !== null ? exports : this;

app = null;

PopupCtrl = (function(_super) {
  __extends(PopupCtrl, _super);

  PopupCtrl.prototype.currentTab = {};

  PopupCtrl.prototype.currentTabId = {};

  function PopupCtrl() {
    this.toggleItem = __bind(this.toggleItem, this);
    PopupCtrl.__super__.constructor.apply(this, arguments);
    this.$scope.currentTabId = this.currentTabId;
    this.$scope.navIsRedirect = true;
    chrome.tabs.query({
      active: true,
      currentWindow: true
    }, (function(_this) {
      return function(tabs) {
        var _base, _base1, _base2, _name;
        _this.currentTab = tabs[0];
        _this.currentTabId = tabs[0].id;
        _this.app.Redirect.currentTabId = _this.currentTab.id;
        _this.app.currentTabId = _this.currentTab.id;
        if ((_base = _this.app).tabMaps == null) {
          _base.tabMaps = {};
        }
        if ((_base1 = _this.app.tabMaps)[_name = _this.currentTabId] == null) {
          _base1[_name] = {};
        }
        if ((_base2 = _this.app.tabMaps[_this.currentTabId]).maps == null) {
          _base2.maps = angular.copy(_this.app.data.maps || []);
        }
        _this.$scope.maps = _this.app.tabMaps[_this.currentTabId].maps;
        return _this.$scope.$apply();
      };
    })(this));
  }

  PopupCtrl.prototype.toggleItem = function(item) {
    var _i, _item, _len, _maps, _ref;
    _maps = [];
    _ref = this.$scope.maps;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      _item = _ref[_i];
      if (_item !== item) {
        _item.isOn = false;
      }
    }
    this.app.Redirect.tab(this.currentTab.id).withMaps(this.$scope.maps);
    return this.app.mapAllResources((function(_this) {
      return function() {
        var isOn;
        isOn = _this.app.Redirect.withPrefix(_this.app.Storage.session.server.status.url).withMaps(_this.$scope.maps).toggle();
        if (isOn) {
          return _this.app.startServer(function() {
            return chrome.tabs.reload(_this.currentTab.id, {
              bypassCache: true
            }, function() {
              _this.app.setBadgeText(null, _this.currentTab.id);
              return window.close();
            });
          });
        } else {
          return chrome.tabs.reload(_this.currentTab.id, {
            bypassCache: true
          }, function() {
            _this.app.removeBadgeText(_this.currentTab.id);
            return window.close();
          });
        }
      };
    })(this));
  };

  return PopupCtrl;

})(ProxlyCtrl);

chrome.runtime.getBackgroundPage((function(_this) {
  return function(win) {
    var dir, e, found, ngRegex, ngapp, nghighlight, _i, _len, _ref, _ref1;
    if (typeof ngapp !== "undefined" && ngapp !== null) {
      return;
    }
    try {
      angular.module('redir-popup');
    } catch (_error) {
      e = _error;
    }
    found = false;
    _ref = win.app.data.directories;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      dir = _ref[_i];
      if (dir.directoryEntryId != null) {
        found = true;
        break;
      }
    }
    if (!(found && ((_ref1 = win.app.data.maps) != null ? _ref1.length : void 0) > 0)) {
      return win.app.openApp();
    }
    nghighlight = angular.module("ui.highlight", []).filter("highlight", function() {
      return function(text, search, caseSensitive) {
        if (text && (search || angular.isNumber(search))) {
          text = text.toString();
          search = search.toString();
          if (caseSensitive) {
            return text.split(search).join("<span class=\"ui-match\">" + search + "</span>");
          } else {
            return text.replace(new RegExp(search, "gi"), "<span class=\"ui-match\">$&</span>");
          }
        } else {
          return text;
        }
      };
    });
    ngapp = angular.module('redir-popup', ['ngSanitize', 'ui.highlight', 'ngAnimate']);
    ngapp.factory('proxlyApp', function() {
      return win.app;
    });
    ngapp.directive('flipSwitch', function() {
      return {
        restrict: 'AE',
        scope: {
          id: "@identifier",
          toggleThis: '&toggleThis',
          _model: '=ngModel'
        },
        template: '<div class="onoffswitch">\n  <input type="checkbox" name="onoffswitch" id="{{id}}" ng-model="_model" ng-change="toggleThis()" class="onoffswitch-checkbox">\n  <label class="onoffswitch-label" for="{{id}}">\n      <span class="onoffswitch-inner"></span>\n      <span class="onoffswitch-switch"></span>\n  </label>\n</div>',
        replace: true
      };
    });
    ngRegex = ngapp.filter("regex", function() {
      return function(input, field, regex) {
        var i, out, patt;
        patt = new RegExp(regex);
        out = [];
        i = 0;
        while (i < input.length) {
          if (patt.test(input[i][field])) {
            out.push(input[i]);
          }
          i++;
        }
        return out;
      };
    });
    PopupCtrl.$inject = ["$scope", "$filter", "$sce", "$document", "$window", "proxlyApp"];
    ngapp.controller('PopupCtrl', PopupCtrl);
    return angular.bootstrap(document, ['redir-popup']);
  };
})(this));