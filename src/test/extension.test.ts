import * as assert from 'assert';
import * as vscode from 'vscode';

suite('Extension Test Suite', () => {
  vscode.window.showInformationMessage('Start all tests.');

  test('Extension should activate without issues', async () => {
    const extensionId = 'kirikintha.artisan-tools';
    const extension = vscode.extensions.getExtension(extensionId);
    assert.ok(extension, 'Extension not found');

    if (extension) {
      await extension.activate();
      assert.ok(extension.isActive, 'Extension did not activate successfully');
    }
  });
});
