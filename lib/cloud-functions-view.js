'use babel';

const {Disposable, CompositeDisposable} = require('atom');
const {View} = require('atom-space-pen-views');
const whenjs = require('when');
let $ = null;
let $$ = null;
const Subscriber = null;
let spark = null;
let MiniEditorView = null;

export default class CloudFunctionsView extends View {
	static content() {
		return this.div({id: 'particle-dev-cloud-functions-container'}, () => {
			return this.div({id: 'particle-dev-cloud-functions', outlet: 'functionsList'});
		});
	}

	initialize(main) {
		this.main = main;
	}

	setup() {
		({$, $$} = require('atom-space-pen-views'));
		({MiniEditorView} = require('particle-dev-views'));

		spark = require('spark');
		spark.login({ accessToken: this.main.profileManager.accessToken });

		this.disposables = new CompositeDisposable;

		this.disposables.add(
			atom.commands.add('atom-workspace', {
				'particle-dev:update-core-status': () => {
					// Show some progress when core's status is downloaded
					this.functionsList.empty();
					return this.addClass('loading');
				},
				'particle-dev:core-status-updated': () => {
					// Refresh UI when current core changes
					this.listFunctions();
					return this.removeClass('loading');
				},
				'particle-dev:logout': () => {
					// Hide when user logs out
					return this.close();
				}
			})
		);

		this.listFunctions();
		return this;
	}

	serialize() {}

	destroy() {
		if (this.hasParent()) {
			this.remove();
		}
		return (this.disposables != null ? this.disposables.dispose() : undefined);
	}

	getTitle() {
		return 'Cloud functions';
	}

	getPath() {
		return 'cloud-functions';
	}

	getUri() {
		return `particle-dev://editor/${this.getPath()}`;
	}

	getDefaultLocation() {
		return 'bottom';
	}

	close() {
		const pane = atom.workspace.paneForUri(this.getUri());
		return (pane != null ? pane.destroy() : undefined);
	}

	getParamsEditor(row) {
		return row.find('.particle-dev-mini-editor-view:eq(0)').view();
	}

	getResultEditor(row) {
		return row.find('.particle-dev-mini-editor-view:eq(1)').view();
	}

	// Propagate table with functions
	listFunctions() {
		const functions = this.main.profileManager.getLocal('functions');
		this.functionsList.empty();
		if (!functions || (functions.length === 0)) {
			this.functionsList.append($$(function() {
				this.ul({class: 'background-message'}, () => {
					this.li('No functions registered');
				});
			})
			);
		} else {
			const result = [];
			for (var func of Array.from(functions)) {
				const row = $$(function() {
					this.div({'data-id': func}, () => {
						this.button({class: 'btn icon icon-zap'}, func);
						this.span('(');
						this.subview('parameters', new MiniEditorView('Parameters'));
						this.span(') == ');
						this.subview('result', new MiniEditorView('Result'));
						this.span({class: 'three-quarters inline-block hidden'});
					});
				});

				row.find('button').on('click', event => {
					this.callFunction($(event.currentTarget).parent().attr('data-id'));
				});

				this.disposables.add(
					atom.commands.add(this.getParamsEditor(row).editor.element, {
						'core:confirm': event => {
							this.callFunction($(event.currentTarget).parent().parent().attr('data-id'));
						}
					})
				);

				this.getResultEditor(row).setEnabled(false);
				result.push(this.functionsList.append(row));
			}
		}
	}

	// Lock/unlock row
	setRowEnabled(row, enabled) {
		if (enabled) {
			row.find('button').removeAttr('disabled');
			this.getParamsEditor(row).setEnabled(true);
			return row.find('.three-quarters').addClass('hidden');
		} else {
			row.find('button').attr('disabled', 'disabled');
			this.getParamsEditor(row).setEnabled(false);
			row.find('.three-quarters').removeClass('hidden');
			return this.getResultEditor(row).removeClass('icon icon-issue-opened');
		}
	}

	// Call function via cloud
	callFunction(functionName) {
		const dfd = whenjs.defer();
		const row = this.find(`#particle-dev-cloud-functions [data-id=${functionName}]`);
		this.setRowEnabled(row, false);
		this.getResultEditor(row).editor.setText(' ');
		const params = this.getParamsEditor(row).editor.getText();
		const promise = spark.callFunction(this.main.profileManager.currentDevice.id, functionName, params);
		promise.done(e => {
			if (!$.contains(document.documentElement, row[0])) {
				return;
			}

			this.setRowEnabled(row, true);

			if (!!e.ok) {
				this.getResultEditor(row).addClass('icon icon-issue-opened');
				console.error('Error calling a function', e);
				return dfd.reject();
			} else {
				this.getResultEditor(row).editor.setText(e.return_value.toString());

				return dfd.resolve(e.return_value);
			}
		}, e => {
			if (!$.contains(document.documentElement, row[0])) {
				return;
			}

			this.setRowEnabled(row, true);
			this.getResultEditor(row).addClass('icon icon-issue-opened');

			return dfd.reject();
		});
		return dfd.promise;
	}
};
