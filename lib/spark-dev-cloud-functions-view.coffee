{Disposable, CompositeDisposable} = require 'atom'
{View} = require 'atom-space-pen-views'
whenjs = require 'when'
$ = null
$$ = null
SettingsHelper = null
Subscriber = null
spark = null
sparkDev = null
MiniEditorView = null

module.exports =
class CloudFunctionsView extends View
  @content: ->
    @div id: 'spark-dev-cloud-functions-container', =>
      @div id: 'spark-dev-cloud-functions', outlet: 'functionsList'

  initialize: (serializeState, mainModule) ->
    sparkDev = mainModule

  setup: ->
    {$, $$} = require 'atom-space-pen-views'
    {MiniEditorView} = require 'spark-dev-views'

    SettingsHelper = sparkDev.SettingsHelper
    spark = require 'spark'
    spark.login { accessToken: SettingsHelper.get('access_token') }

    @disposables = new CompositeDisposable

    @disposables.add atom.commands.add 'atom-workspace',
      'spark-dev:update-core-status': =>
        # Show some progress when core's status is downloaded
        @functionsList.empty()
        @addClass 'loading'
      'spark-dev:core-status-updated': =>
        # Refresh UI when current core changes
        @listFunctions()
        @removeClass 'loading'
      'spark-dev:logout': =>
        # Hide when user logs out
        @close()

    @listFunctions()
    @

  serialize: ->

  destroy: ->
    if @hasParent()
      @remove()
    @disposables?.dispose()

  getTitle: ->
    'Cloud functions'

  # TODO: Remove both of these post 1.0
  onDidChangeTitle: (callback) -> new Disposable()
  onDidChangeModified: (callback) -> new Disposable()

  getPath: ->
    'cloud-functions'

  getUri: ->
    'spark-dev://editor/' + @getPath()

  close: ->
    pane = atom.workspace.paneForUri @getUri()
    pane?.destroy()

  getParamsEditor: (row) ->
    row.find('.spark-dev-mini-editor-view:eq(0)').view()

  getResultEditor: (row) ->
    row.find('.spark-dev-mini-editor-view:eq(1)').view()

  # Propagate table with functions
  listFunctions: ->
    functions = SettingsHelper.getLocal 'functions'
    @functionsList.empty()
    if !functions || functions.length == 0
      @functionsList.append $$ ->
        @ul class: 'background-message', =>
          @li 'No functions registered'
    else
      for func in functions
        row = $$ ->
          @div 'data-id': func, =>
            @button class: 'btn icon icon-zap', func
            @span '('
            @subview 'parameters', new MiniEditorView('Parameters')
            @span ') == '
            @subview 'result', new MiniEditorView('Result')
            @span class: 'three-quarters inline-block hidden'

        row.find('button').on 'click', (event) =>
          @callFunction $(event.currentTarget).parent().attr('data-id')

        @disposables.add atom.commands.add @getParamsEditor(row).editor.element,
          'core:confirm': (event) =>
            @callFunction $(event.currentTarget).parent().parent().attr('data-id')

        @getResultEditor(row).setEnabled false
        @functionsList.append row

  # Lock/unlock row
  setRowEnabled: (row, enabled) ->
    if enabled
      row.find('button').removeAttr 'disabled'
      @getParamsEditor(row).setEnabled true
      row.find('.three-quarters').addClass 'hidden'
    else
      row.find('button').attr 'disabled', 'disabled'
      @getParamsEditor(row).setEnabled false
      row.find('.three-quarters').removeClass 'hidden'
      @getResultEditor(row).removeClass 'icon icon-issue-opened'

  # Call function via cloud
  callFunction: (functionName) ->
    dfd = whenjs.defer()
    row = @find('#spark-dev-cloud-functions [data-id=' + functionName + ']')
    @setRowEnabled row, false
    @getResultEditor(row).editor.setText ' '
    params = @getParamsEditor(row).editor.getText()
    promise = spark.callFunction SettingsHelper.getLocal('current_core'), functionName, params
    promise.done (e) =>
      if !$.contains(document.documentElement, row[0])
        return

      @setRowEnabled row, true

      if !!e.ok
        @getResultEditor(row).addClass 'icon icon-issue-opened'
        dfd.reject()
      else
        @getResultEditor(row).editor.setText e.return_value.toString()

        dfd.resolve e.return_value
    , (e) =>
      if !$.contains(document.documentElement, row[0])
        return

      @setRowEnabled row, true
      @getResultEditor(row).addClass 'icon icon-issue-opened'

      dfd.reject()
    dfd.promise
