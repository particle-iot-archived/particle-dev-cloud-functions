{View, TextEditorView} = require 'atom'
{Emitter} = require 'event-kit'
$ = null
$$ = null
whenjs = require 'when'
SettingsHelper = null
Subscriber = null
spark = null
sparkDev = null

module.exports =
class CloudFunctionsView extends View
  @content: ->
    @div id: 'spark-dev-cloud-functions-container', =>
      @div id: 'spark-dev-cloud-functions', outlet: 'functions'

  initialize: (serializeState, mainModule) ->
    sparkDev = mainModule

  setup: ->
    {$, $$} = require 'atom'
    {Subscriber} = require 'emissary'

    SettingsHelper = sparkDev.SettingsHelper
    spark = require 'spark'
    spark.login { accessToken: SettingsHelper.get('access_token') }

    @emitter = new Emitter
    @subscriber = new Subscriber()
    # Show some progress when core's status is downloaded
    @subscriber.subscribeToCommand atom.workspaceView, 'spark-dev:update-core-status', =>
      @functions.empty()
      @addClass 'loading'

    @subscriber.subscribeToCommand atom.workspaceView, 'spark-dev:core-status-updated', =>
      # Refresh UI when current core changes
      @listFunctions()
      @removeClass 'loading'

    @subscriber.subscribeToCommand atom.workspaceView, 'spark-dev:logout', =>
      # Hide when user logs out
      @close()

    @listFunctions()

    @

  serialize: ->

  destroy: ->
    if @hasParent()
      @remove()

  getTitle: ->
    'Cloud functions'

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  onDidChangeModified: (callback) ->
    @emitter.on 'did-change-modified', callback

  getUri: ->
    'spark-dev://editor/cloud-functions'

  close: ->
    pane = atom.workspace.paneForUri @getUri()
    pane?.destroy()

  # Propagate table with functions
  listFunctions: ->
    functions = SettingsHelper.getLocal 'functions'

    @functions.empty()
    if !functions || functions.length == 0
      @functions.append $$ ->
        @ul class: 'background-message', =>
          @li 'No functions registered'
    else
      for func in functions
        row = $$ ->
          @div 'data-id': func, =>
            @button class: 'btn icon icon-zap', func
            @span '('
            @subview 'parameters', new TextEditorView(mini: true, placeholderText: 'Parameters')
            @span ') == '
            @subview 'result', new TextEditorView(mini: true, placeholderText: 'Result')
            @span class: 'three-quarters inline-block hidden'
        row.find('button').on 'click', (event) =>
          @callFunction $(event.currentTarget).parent().attr('data-id')
        row.find('.editor:eq(0)').view().on 'core:confirm', (event) =>
          @callFunction $(event.currentTarget).parent().attr('data-id')
        row.find('.editor:eq(1)').view().hiddenInput.attr 'disabled', 'disabled'
        @functions.append row

  # Lock/unlock row
  setRowEnabled: (row, enabled) ->
    if enabled
      row.find('button').removeAttr 'disabled'
      row.find('.editor:eq(0)').view().hiddenInput.removeAttr 'disabled'
      row.find('.three-quarters').addClass 'hidden'
    else
      row.find('button').attr 'disabled', 'disabled'
      row.find('.editor:eq(0)').view().hiddenInput.attr 'disabled', 'disabled'
      row.find('.three-quarters').removeClass 'hidden'
      row.find('.editor:eq(1)').view().removeClass 'icon icon-issue-opened'

  # Call function via cloud
  callFunction: (functionName) ->
    dfd = whenjs.defer()
    row = @find('#spark-dev-cloud-functions [data-id=' + functionName + ']')
    @setRowEnabled row, false
    row.find('.editor:eq(1)').view().setText ' '
    params = row.find('.editor:eq(0)').view().getText()
    promise = spark.callFunction SettingsHelper.getLocal('current_core'), functionName, params
    promise.done (e) =>
      if !$.contains(document.documentElement, row[0])
        return

      @setRowEnabled row, true

      if !!e.ok
        row.find('.editor:eq(1)').view().addClass 'icon icon-issue-opened'
        dfd.reject()
      else
        row.find('.editor:eq(1)').view().setText e.return_value.toString()

        dfd.resolve e.return_value
    , (e) =>
      if !$.contains(document.documentElement, row[0])
        return
        
      @setRowEnabled row, true
      row.find('.editor:eq(1)').view().addClass 'icon icon-issue-opened'

      dfd.reject()
    dfd.promise
