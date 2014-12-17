SparkDevCloudFunctionsView = require './spark-dev-cloud-functions-view'

module.exports =
  sparkDevCloudFunctionsView: null

  activate: (state) ->
    atom.packages.activatePackage('spark-dev').then ({mainModule}) =>
      # Any Spark Dev dependent code should be placed here
      sparkDev = mainModule
      @sparkDevCloudFunctionsView = new SparkDevCloudFunctionsView(state.sparkDevCloudFunctionsViewState, sparkDev)

      url = require 'url'
      atom.workspace.addOpener (uriToOpen) =>
        if uriToOpen == @sparkDevCloudFunctionsView.getUri()
          @sparkDevCloudFunctionsView.setup()

      atom.workspaceView.command 'spark-dev-cloud-functions-view:show-cloud-functions', =>
        atom.workspace.open @sparkDevCloudFunctionsView.getUri()

      atom.workspaceView.command 'spark-dev:update-menu', =>
        # Add itself to menu if user is authenticated
        if sparkDev.SettingsHelper.isLoggedIn()
          sparkDev.MenuManager.append [
            {
              label: 'Show cloud functions',
              command: 'spark-dev-cloud-functions-view:show-cloud-functions'
            }
          ]
      atom.workspaceView.trigger 'spark-dev:update-menu'

  deactivate: ->
    @sparkDevCloudFunctionsView?.destroy()

  serialize: ->
    sparkDevCloudFunctionsViewState: @sparkDevCloudFunctionsView?.serialize()
