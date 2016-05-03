{$} = require 'atom-space-pen-views'
SparkStub = require('particle-dev-spec-stubs').spark
ParticleDevCloudFunctionsView = require '../lib/cloud-functions-view'
spark = require 'spark'
SettingsHelper = null

describe 'Cloud Functions View', ->
  activationPromise = null
  originalProfile = null
  particleDev = null
  cloudFunctions = null
  cloudFunctionsView = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    activationPromise = atom.packages.activatePackage('particle-dev-cloud-functions').then ({mainModule}) ->
      cloudFunctions = mainModule

    particleDevPromise = atom.packages.activatePackage('particle-dev').then ({mainModule}) ->
      particleDev = mainModule
      SettingsHelper = particleDev.SettingsHelper

    waitsForPromise ->
      activationPromise

    waitsForPromise ->
      particleDevPromise

    runs ->
      originalProfile = SettingsHelper.getProfile()
      # For tests not to mess up our profile, we have to switch to test one...
      SettingsHelper.setProfile 'particle-dev-test'

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
      cloudFunctionsView = new ParticleDevCloudFunctionsView(null, particleDev)
      cloudFunctionsView.setup()

      # Tests particle-dev:update-core-status
      spyOn cloudFunctionsView, 'listFunctions'
      atom.commands.dispatch workspaceElement, 'particle-dev:core-status-updated'
      expect(cloudFunctionsView.listFunctions).toHaveBeenCalled()
      jasmine.unspy cloudFunctionsView, 'listFunctions'

      # Tests particle-dev:logout
      SettingsHelper.clearCredentials()
      spyOn cloudFunctionsView, 'close'
      atom.commands.dispatch workspaceElement, 'particle-dev:logout'
      expect(cloudFunctionsView.close).toHaveBeenCalled()
      jasmine.unspy cloudFunctionsView, 'close'
      cloudFunctionsView.detach()
