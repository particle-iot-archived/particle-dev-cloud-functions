'use babel';

let CloudFunctionsView = null;
let CompositeDisposable = null;

export default {
	cloudFunctionsView: null,

	activate(state) {
		({CompositeDisposable} = require('atom'));
		this.disposables = new CompositeDisposable;
		this.workspaceElement = atom.views.getView(atom.workspace);

		return atom.packages.activatePackage('particle-dev').then(({mainModule}) => {
			this.main = mainModule;
			// Any Particle Dev dependent code should be placed here
			CloudFunctionsView = require('./cloud-functions-view');
			this.cloudFunctionsView = new CloudFunctionsView(this.main);

			this.disposables.add(
				atom.commands.add('atom-workspace', {
					'particle-dev:append-menu': () => {
						// Add itself to menu if user is authenticated
						if (this.main.profileManager.isLoggedIn) {
							return this.main.MenuManager.append([
								{
									label: 'Show cloud functions',
									command: 'particle-dev-cloud-functions-view:show-cloud-functions'
								}
							]);
						}
					},
					'particle-dev-cloud-functions-view:show-cloud-functions': () => {
						this.show();
					}
				})
			);

			return atom.commands.dispatch(this.workspaceElement, 'particle-dev:update-menu');
		});
	},

	deactivate() {
		if (this.cloudFunctionsView != null) {
			this.cloudFunctionsView.destroy();
		}
		return this.disposables.dispose();
	},

	show() {
		atom.workspace.open(this.cloudFunctionsView.setup());
	}
};
