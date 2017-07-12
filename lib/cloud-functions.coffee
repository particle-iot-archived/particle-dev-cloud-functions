ParticleDevCloudFunctionsView = require './cloud-functions-view'

CompositeDisposable = null

module.exports =
  particleDevCloudFunctionsView: null

  activate: (state) ->
    {CompositeDisposable} = require 'atom'
    @disposables = new CompositeDisposable
    @workspaceElement = atom.views.getView(atom.workspace)

    atom.packages.activatePackage('particle-dev').then ({mainModule}) =>
      @main = mainModule
      # Any Particle Dev dependent code should be placed here
      @particleDevCloudFunctionsView = new ParticleDevCloudFunctionsView(state.particleDevCloudFunctionsViewState, @main)

      url = require 'url'
      atom.workspace.addOpener (uriToOpen) =>
        if uriToOpen == @particleDevCloudFunctionsView.getUri()
          @particleDevCloudFunctionsView.setup()

      @disposables.add atom.commands.add 'atom-workspace',
        'particle-dev:append-menu': =>
          # Add itself to menu if user is authenticated
          if @main.profileManager.isLoggedIn
            @main.MenuManager.append [
              {
                label: 'Show cloud functions',
                command: 'particle-dev-cloud-functions-view:show-cloud-functions'
              }
            ]
        'particle-dev-cloud-functions-view:show-cloud-functions': =>
          @main.openPane @particleDevCloudFunctionsView.getPath()

      atom.commands.dispatch @workspaceElement, 'particle-dev:update-menu'

  deactivate: ->
    @particleDevCloudFunctionsView?.destroy()
    @disposables.dispose()

  serialize: ->
    particleDevCloudFunctionsViewState: @particleDevCloudFunctionsView?.serialize()
