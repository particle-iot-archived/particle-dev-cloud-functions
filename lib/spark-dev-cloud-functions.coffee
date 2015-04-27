SparkDevCloudFunctionsView = require './spark-dev-cloud-functions-view'

CompositeDisposable = null

module.exports =
  sparkDevCloudFunctionsView: null

  activate: (state) ->
    {CompositeDisposable} = require 'atom'
    @disposables = new CompositeDisposable
    @workspaceElement = atom.views.getView(atom.workspace)

    atom.packages.activatePackage('spark-dev').then ({mainModule}) =>
      # Any Spark Dev dependent code should be placed here
      sparkDev = mainModule
      @sparkDevCloudFunctionsView = new SparkDevCloudFunctionsView(state.sparkDevCloudFunctionsViewState, sparkDev)

      url = require 'url'
      atom.workspace.addOpener (uriToOpen) =>
        if uriToOpen == @sparkDevCloudFunctionsView.getUri()
          @sparkDevCloudFunctionsView.setup()

      @disposables.add atom.commands.add 'atom-workspace',
        'spark-dev:append-menu': =>
          # Add itself to menu if user is authenticated
          if sparkDev.SettingsHelper.isLoggedIn()
            sparkDev.MenuManager.append [
              {
                label: 'Show cloud functions',
                command: 'spark-dev-cloud-functions-view:show-cloud-functions'
              }
            ]
        'spark-dev-cloud-functions-view:show-cloud-functions': =>
          sparkDev.openPane @sparkDevCloudFunctionsView.getPath()

      atom.commands.dispatch @workspaceElement, 'spark-dev:update-menu'

  deactivate: ->
    @sparkDevCloudFunctionsView?.destroy()
    @disposables.dispose()

  serialize: ->
    sparkDevCloudFunctionsViewState: @sparkDevCloudFunctionsView?.serialize()
