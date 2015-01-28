var cdb = require('cartodb.js');
var _ = require('underscore');
var $ = require('jquery');
var BaseDialog = require('new_common/views/base_dialog/view');
var StartView = require('./change_privacy/start_view');
var ShareView = require('./change_privacy/share_view');
var PrivacyOptions = require('./change_privacy/options_collection');


/**
 * Change privacy datasets/maps dialog.
 */
module.exports = BaseDialog.extend({

  initialize: function() {
    this.elder('initialize');
    this._vis = this.options.vis;
    this._user = this.options.user;
    this._upgradeUrl = this.options.upgradeUrl;
    this._privacyOptions = PrivacyOptions.byVisAndUser(this._vis, this._user);
    
    if (this._user.organization) {
      this._permission = this._vis.permission.clone();
    }

    this._contentPane = this._newContentPane();
    this._contentPane.active('start_view');
    this.addView(this._contentPane);
  },

  /**
   * @implements cdb.ui.common.Dialog.prototype.render_content
   */
  render_content: function() {
    return [
      this._renderHeaderTemplate(),
      this._renderActiveContentPane().el
    ];
  },

  _renderHeaderTemplate: function() {
    return $(
      cdb.templates.getTemplate('new_dashboard/dialogs/change_privacy/header_template')({
        itemName: this._vis.get('name')
      })
    )[0];
  },

  _renderActiveContentPane: function() {
    var view = this._contentPane.getActivePane();
    view.delegateEvents(); // For some reason events gets undelegated upon changing pane, so force enable on activate
    return view.render();
  },

  _newContentPane: function() {
    var pane = new cdb.ui.common.TabPane();
    pane.addTab('start_view', new StartView({
      vis: this._vis,
      user: this._user,
      upgradeUrl: this._upgradeUrl,
      privacyOptions: this._privacyOptions
    }));

    // Will only have permissions if current user is part of an organization
    if (this._hasOrganization()) {
      pane.addTab('share_view', new ShareView({
        organization: this._user.organization,
        permission: this._permission,
        canChangeWriteAccess: !this._vis.isVisualization()
      }));
      pane.getPane('share_view').bind('click:back', function() {
        this._contentPane.active('start_view');
        this.render();
        this.$('.content').removeClass('Dialog-content--expanded');
      }, this);
      pane.getPane('start_view').bind('click:share', function() {
        this._contentPane.active('share_view');
        this.render();
        this.$('.content').addClass('Dialog-content--expanded');
      }, this);
    }
    
    pane.each(function(name, view) {
      view.bind('click:save', this._save, this);
    }.bind(this));
    
    return pane;
  },
  
  cancel: function() {
    this.clean();
  },

  _save: function() {
    var selectedOption = this._privacyOptions.selectedOption();
    if (selectedOption.canSave()) {
      this._contentPane.each(function(name, view) {
        view.undelegateEvents();
      });

      var self = this;
      selectedOption.saveToVis(this._vis)
        .done(function() {
          if (self._hasOrganization()) {
            self._savePermissionChanges()
          } else {
            self.close()
          }
        })
        .fail(this._delegateAllEvents.bind(this));
    }
  },
  
  _savePermissionChanges: function() {
    var originalPermission = this._vis.permission;
    originalPermission.overwriteAcl(this._permission);
    originalPermission.save()
      .done(this.close.bind(this))
      .fail(this._delegateAllEvents.bind(this));
  },
  
  _hasOrganization: function() {
    return !!this._permission;
  },
  
  _delegateAllEvents: function() {
    this._contentPane.each(function(name, view) {
      view.delegateEvents();
    });
  }
});