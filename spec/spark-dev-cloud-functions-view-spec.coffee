{$} = require 'atom-space-pen-views'
SparkStub = require('spark-dev-spec-stubs').spark
SparkDevCloudFunctionsView = require '../lib/spark-dev-cloud-functions-view'
spark = require 'spark'
SettingsHelper = null

describe 'Cloud Functions View', ->
  activationPromise = null
  originalProfile = null
  sparkDev = null
  sparkDevCloudFunctions = null
  sparkDevCloudFunctionsView = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

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
      @sparkDevCloudFunctionsView = new SparkDevCloudFunctionsView(null, sparkDev)
      @sparkDevCloudFunctionsView.setup()

      # Tests spark-dev:update-core-status
      spyOn @sparkDevCloudFunctionsView, 'listFunctions'
      atom.commands.dispatch workspaceElement, 'spark-dev:core-status-updated'
      expect(@sparkDevCloudFunctionsView.listFunctions).toHaveBeenCalled()
      jasmine.unspy @sparkDevCloudFunctionsView, 'listFunctions'

      # Tests spark-dev:logout
      SettingsHelper.clearCredentials()
      spyOn @sparkDevCloudFunctionsView, 'close'
      atom.commands.dispatch workspaceElement, 'spark-dev:logout'
      expect(@sparkDevCloudFunctionsView.close).toHaveBeenCalled()
      jasmine.unspy @sparkDevCloudFunctionsView, 'close'
      @sparkDevCloudFunctionsView.detach()
