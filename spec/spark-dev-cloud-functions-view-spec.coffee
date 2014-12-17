{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = null
SparkStub = require('spark-dev-spec-stubs').spark
spark = require 'spark'

describe 'Cloud Functions View', ->
  activationPromise = null
  originalProfile = null
  sparkDev = null
  sparkDevCloudFunctions = null
  sparkDevCloudFunctionsView = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView

    activationPromise = atom.packages.activatePackage('spark-dev-cloud-functions').then ({mainModule}) ->
      sparkDevCloudFunctions = mainModule

    sparkDevPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
      sparkDev = mainModule
      SettingsHelper = sparkDev.SettingsHelper

    waitsForPromise ->
      activationPromise

    waitsForPromise ->
      sparkDevPromise

    runs ->
      originalProfile = SettingsHelper.getProfile()
      # For tests not to mess up our profile, we have to switch to test one...
      SettingsHelper.setProfile 'spark-dev-test'

  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe '', ->
    beforeEach ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      SettingsHelper.setLocal 'functions', ['bar']

    afterEach ->
      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()
      SettingsHelper.setLocal 'functions', []

    it 'checks hiding and showing', ->
      SparkStub.stubSuccess spark, 'getVariable'
      atom.workspaceView.trigger 'spark-dev-cloud-functions-view:show-cloud-functions'

      waitsFor ->
        !!sparkDevCloudFunctions.sparkDevCloudFunctionsView && sparkDevCloudFunctions.sparkDevCloudFunctionsView.hasParent()

      runs ->
        @sparkDevCloudFunctionsView = sparkDevCloudFunctions.sparkDevCloudFunctionsView

        expect(atom.workspaceView.find('#spark-dev-cloud-functions')).toExist()
        @sparkDevCloudFunctionsView.close()
        expect(atom.workspaceView.find('#spark-dev-cloud-functions')).not.toExist()

    it 'checks event hooks', ->
      SparkStub.stubSuccess spark, 'getVariable'
      atom.workspaceView.trigger 'spark-dev-cloud-functions-view:show-cloud-functions'

      waitsFor ->
        !!sparkDevCloudFunctions.sparkDevCloudFunctionsView && sparkDevCloudFunctions.sparkDevCloudFunctionsView.hasParent()

      runs ->
        @sparkDevCloudFunctionsView = sparkDevCloudFunctions.sparkDevCloudFunctionsView

        # Tests spark-dev:update-core-status
        spyOn @sparkDevCloudFunctionsView, 'listFunctions'
        atom.workspaceView.trigger 'spark-dev:core-status-updated'
        expect(@sparkDevCloudFunctionsView.listFunctions).toHaveBeenCalled()
        jasmine.unspy @sparkDevCloudFunctionsView, 'listFunctions'

        # Tests spark-dev:logout
        SettingsHelper.clearCredentials()
        spyOn @sparkDevCloudFunctionsView, 'close'
        atom.workspaceView.trigger 'spark-dev:logout'
        expect(@sparkDevCloudFunctionsView.close).toHaveBeenCalled()
        jasmine.unspy @sparkDevCloudFunctionsView, 'close'
        @sparkDevCloudFunctionsView.detach()
