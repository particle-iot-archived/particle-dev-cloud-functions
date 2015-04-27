SparkDevCloudFunctions = require '../lib/spark-dev-cloud-functions'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "SparkDevCloudFunctions", ->
  activationPromise = null
  sparkDevPromise = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

  describe "when Spark Dev package is activated", ->
    it "sets up variables, openers and commands", ->
      spyOn atom.workspace, 'addOpener'

      sparkDevPromise = atom.packages.activatePackage('spark-dev')
      activationPromise = atom.packages.activatePackage('spark-dev-cloud-functions')

      waitsForPromise ->
        sparkDevPromise

      runs ->
        expect(atom.workspace.addOpener).toHaveBeenCalled()
