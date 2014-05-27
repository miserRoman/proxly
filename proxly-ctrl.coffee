

class @BaseCtrl
  @register: (app, name) ->
    name ?= @name || @toString().match(/function\s*(.*?)\(/)?[1]
    app.controller name, @

  @inject: (args...) ->
    @$inject = args

  constructor: (args...) ->
    for key, index in @constructor.$inject
      @[key] = args[index]

    for key, fn of @constructor.prototype
      continue unless typeof fn is 'function'
      continue if key in ['constructor', 'initialize'] or key[0] is '_'
      @$scope[key] = fn.bind?(@) || _.bind(fn, @)

    @initialize?()

class ProxlyCtrl extends @BaseCtrl
  # @register app
  @inject "$scope", "$filter", "$sce", "$document", "$window", "dndFile", "proxlyApp"

  initialize: ->
    @app = @proxlyApp


    @data = @app.Storage.data

    @$scope.server = @app.Storage.session.server.status
    # @$scope.data = @app.data
    @$scope.maps = @data.maps 
    @$scope.directories = @data.directories 
    @$scope.save = @save
    @$scope.resourceMap = @resourceMap = []
    @$scope.currentResources = @app.data.currentResources
    @$scope.currentResources ?= []
    # @$scope.getResources = @getResources
    @$scope.urlFilter = @urlFilter = 'resource'
    # @$scope.findMatches = @findMatches
    @$scope.foundFiles = {}
    @$scope.dirDisplay = {}
    @$scope.currentFilter = {}
    # @$scope.setCurrentFilter = @setCurrentFilter
    # @$scope.trustAsResourceUrl = @trustAsResourcUrl
    @$scope.urls = {}
    @$scope.serverCheckbox = @app.Server.status.isOn
    @$scope.$watch 'server.isOn', (newValue, oldValue) =>
      @$scope.serverCheckbox = newValue

    @$scope.currentFileMatches = @data.currentFileMatches
    @$scope.$watch 'currentFilter', (newValue, oldValue) =>
      @$scope.setLocalPath newValue
    @dnd = new @dndFile 'html', @onDrop if @dndFile?
    # $document.on 'dragenter', @onDrop

    # @app.Storage.retrieveAll () =>
    #   if @data.maps? then @setLocalPath item for item in @data.maps

    @$scope.presets = [
      presetName:'Salesforce'
      url:'https.*\/resource(\/[0-9]+)?\/([A-Za-z0-9\-._]+\/)?'
      regexRepl:''
      ]

    @$scope.navIsRedirect=false
    @$scope.showResources=false

    # @checkIsExtensionInstalled()


  # checkIsExtensionInstalled: () ->
  #   chrome.management.get @app.EXTENSION_ID, (extInfo) =>
  #     @$scope.extInfo = @extInfo = extInfo

  # installExtension: () ->
  #   chrome.webstore.install()

  onDrop: (event) =>
    entry = event.items[0]?.webkitGetAsEntry?()
    return unless entry?.isDirectory
    @app.FS.openDirectory entry, (err, pathName, dir) =>
      dir.name = pathName.match(/[^\/]+$/)?[0]
      delete dir.entry
      dir.pathName = pathName
      dir.isOn = true
      @data.directories.push dir
      @$scope.$apply()

  # save: (close) ->
  #   @app.Storage.saveAllAndSync()
  #   chrome.app.window.current().close() if close
  #     # @app.Storage.set resourceMap:@$scope.resourceMap

  refreshCurrentResources: () ->
    @app.getResources (err, currentResources) =>
      show 'got res'
      show currentResources
      @$scope.currentResources = currentResources
      @$scope.$apply()

  newDirectory: () ->
    @openDirectory (err, pathName, dir) =>
      @$scope.$apply()

  newMapping: (item) ->
    newItem = if item? then angular.copy(item) else {}
    newItem.isRedirect = true
    newItem.isOn = false
    newItem.url = newItem.regexRepl = '' 
    @data.maps.push newItem
    newItem.name = 'Redirect ' + @data.maps.length
    # @openDirectory newItem, (pathName, dir) =>
    #   newItem.name = pathName.match(/[^\/]+$/)?[0]
    #   newItem.directory = pathName
    #   @setLocalPath newItem
    #   @data.maps.push newItem      
    #   @$scope.currentFilter = item
    #   @$scope.$apply()

  deleteDirectory: (item) ->
    idx = @data.directories.indexOf item
    @data.directories.splice(idx, 1) if idx >= 0

  deleteMapping: (item) ->
    idx = @data.maps.indexOf item
    @data.maps.splice(idx, 1) if idx >= 0
    @currentFilter = {}

  setLocalPath: (item) ->
    
    try
      reg = new RegExp item.url
      item.regexIsWrong = false
    catch e
      item.regexIsWrong = true
      @$scope.$apply()
      return 
    
    # @$scope.currentFilter = angular.copy item unless item.regexIsWrong
    if @$scope.filteredResources?
      for resource in @$scope.filteredResources
        resource.localPath = resource.url.replace(reg, item.regexRepl)
        _dirs = [] 
        _dirs.push dir for dir in @$scope.directories when dir.isOn
        @app.getFileMatch resource.localPath, (err, fileMatch, directory) => 
          if err?             
            for res in @$scope.filteredResources when res is resource
              res.localFile = ''
          else
            for res in @$scope.filteredResources when res.localPath is fileMatch.filePath
              res.localFile = directory.pathName + '/' + res.localPath
          @$scope.$apply()


  openDirectory: (cb) ->
    # @app.FS.openDirectory (pathName, dir) =>
    chrome.fileSystem.chooseEntry type:'openDirectory', (directoryEntry, files) =>
      @app.FS.openDirectory directoryEntry, (err, pathName, dir) =>
        dir.name = pathName.match(/[^\/]+$/)?[0]
        dir.pathName = pathName    
        dir.isOn = true    
        # can't save circular blah blah
        delete dir.entry
        @data.directories.push dir
        cb?(pathName,dir)

  setCurrentFilter: (item) ->
    @$scope.currentFilter = angular.copy item


  getHtmlSafe: (text) ->
    @sce.trustAsHtml text

  toggleServer: () ->
    if @$scope.server.isOn
      @app.stopServer =>
        @$scope.$apply()
    else
      @app.startServer =>
        @$scope.$apply()

  getClass: (type, item) ->
    if type is 'on'
      if item.isOn then 'btn-success' else 'btn-default'
    else
      if item.isOn then 'btn-default' else 'btn-danger'

  newItem: () ->
    if @$scope.navIsRedirect
      @newMapping()
    else
      @newDirectory()

  toggleItem: (item) ->
    item.isOn = true unless item.isOn?
    item.isOn = !item.isOn

  getFullDirList: (directories) ->
    for own key, d of directories
      @getOneDirList d

  getDirList: (d) ->
    @lsR d.entry, (results) ->
      d.list = results
    ,(error, results) ->
      show(error, results)

  getOneDirList: (d) ->
    if d.entry?
      @getDirList d
    else
      @app.FS.restoreEntry d.directoryEntryId, (entry) ->
        d.entry = entry
        @getDirList d

  findMatches: ->
    if @$scope.directoryEntry?
      promises = []
      for item in @$filter('filter')(@$scope.resourceMap, 'url':@$scope.urlFilter, false)
        do (item) =>
          @$findFile(@$scope.directoryEntry, item.url, -1)
          .then (something) ->
            show 'something'

        # @q.all(promises).then (results) ->

    else
      @app.openDirectory()

  trustAsResourcUrl: (url) ->
    $sce.trustAsResourceUrl url

module.exports = ProxlyCtrl



