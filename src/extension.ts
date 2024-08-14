// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
// https://code.visualstudio.com/api/references/icons-in-labels
import * as vscode from 'vscode';
import { ArtisanTreeDataProvider } from './treedata.provider';

/**
 * @brief Activates the Laravel Tools extension.
 *
 * This function is called when the extension is activated. It sets up the status bar item,
 * registers commands, and handles subscriptions.
 *
 * @param context The extension context provided by VS Code.
 */
export function activate(context: vscode.ExtensionContext) {
  const artisanData = new ArtisanTreeDataProvider();

  const treeView = vscode.window.createTreeView('laravelTools', {
    treeDataProvider: artisanData,
  });

  // Show or hide the status bar item based on the visibility of the tree view
  treeView.onDidChangeVisibility((e) => {
    if (e.visible) {
      statusBarItem.show();
    } else {
      statusBarItem.hide();
    }
  });

  // Create a status bar item
  const statusBarItem = vscode.window.createStatusBarItem(
    vscode.StatusBarAlignment.Right,
    100,
  );
  statusBarItem.text = '$(tools) Artisan';
  statusBarItem.command = 'laravelTools.showChannel';
  statusBarItem.show();

  // Add a command to refresh the view
  vscode.commands.registerCommand('laravelTools.refresh', () => {
    artisanData.refresh();
  });

  context.subscriptions.push(
    vscode.commands.registerCommand('laravelTools.make', (command: string) => {
      artisanData.make(command, statusBarItem);
    }),
  );

  vscode.commands.registerCommand('laravelTools.showChannel', () => {
    artisanData.showChannel();
  });

  context.subscriptions.push(statusBarItem);
}

/**
 * @brief Deactivates the Laravel Tools extension.
 *
 * This function is called when the extension is deactivated.
 */
export function deactivate() {
  console.log('deactivated');
}
