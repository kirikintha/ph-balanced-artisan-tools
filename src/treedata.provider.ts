import * as vscode from 'vscode';
import { exec, spawn } from 'child_process';
import { existsSync } from 'fs';
import { join } from 'path';

/**
 * @class ArtisanTreeDataProvider
 * @brief Provides data for the Laravel Artisan commands tree view in VS Code.
 *
 * This class implements the vscode.TreeDataProvider interface to provide
 * Laravel Artisan commands as tree items in the VS Code explorer.
 * It also manages the execution of Artisan commands in the terminal or
 * by spawning new processes.
 */

type ArtisanEventEmmiter = vscode.TreeItem | undefined | void;
class ArtisanTreeDataProvider
  implements vscode.TreeDataProvider<vscode.TreeItem>
{
  private _onDidChangeTreeData: vscode.EventEmitter<ArtisanEventEmmiter> =
    new vscode.EventEmitter<ArtisanEventEmmiter>();
  readonly onDidChangeTreeData: vscode.Event<ArtisanEventEmmiter> =
    this._onDidChangeTreeData.event;

  public commands: vscode.TreeItem[] = [];
  private workspacePath: string = '';
  private outputChannel: vscode.OutputChannel;
  private terminal!: vscode.Terminal;
  private commandOutput: string[] = [];
  constructor() {
    this.outputChannel = vscode.window.createOutputChannel('Laravel Tools');
    this.checkArtisan();
  }

  refresh(): void {
    this.checkArtisan();
  }

  getTreeItem(element: vscode.TreeItem): vscode.TreeItem {
    return element;
  }

  getChildren(element?: vscode.TreeItem): Thenable<vscode.TreeItem[]> {
    if (element) {
      return Promise.resolve([]);
    } else {
      return Promise.resolve(this.commands);
    }
  }

  /**
   * @brief Checks for the existence of the Artisan file in the workspace and generates the list of Artisan commands.
   *
   * This method performs the following steps:
   * - Retrieves the workspace path.
   * - Executes a shell command to check for Artisan make commands.
   * - If no commands are found, logs a message to the output channel.
   * - If commands are found, generates the list of commands by parsing the output.
   *
   * @throws Error if there is an issue executing the shell command.
   */
  private checkArtisan() {
    try {
      this.getWorkspace();
      const commands = [
        `cd ${this.workspacePath}`,
        'php -d xdebug.mode=off -d xdebug.start_with_request=no artisan make --help 2>&1',
      ];
      exec(commands.join(' && '), (error, stdout) => {
        if (!stdout) {
          this.outputChannel.appendLine('No artisan make commands found.');
        }
        this.generateCommands(stdout);
      });
    } catch (error: unknown) {
      if (error instanceof Error) this.outputChannel.appendLine(error.message);
    }
  }

  /**
   * @brief Generates the list of Artisan commands from the provided stdout string.
   *
   * This method performs the following steps:
   * - Logs the stdout content to the output channel.
   * - Uses a regular expression to extract Artisan make commands from the stdout.
   * - Sorts the extracted commands.
   * - Creates an array of objects with label and value properties for each command.
   * - Updates the `commands` property with the generated list of tree items.
   *
   * @param stdout The standard output string from the Artisan make command help.
   */
  private generateCommands(stdout: string) {
    this.outputChannel.appendLine('Found Artisan, generating command list');
    this.outputChannel.appendLine(stdout);
    // Extract commands using regex
    const commandRegex = /make:[a-zA-Z0-9-]+/g;
    const commands = stdout.match(commandRegex)?.sort() ?? [];

    // Create an array of objects with label and value properties
    const generators = commands.map((command) => {
      const value = command.trim();
      let label =
        stdout
          .split('\n')
          .find((line) => line.includes(value))
          ?.trim() ?? '';
      label = label.replace(value, '').trim();
      label = label.replace(/\[[^]]*\]/g, '').trim();
      return { label, value };
    });

    this.commands = generators.map((generator) => {
      const item = new vscode.TreeItem(
        generator.label,
        vscode.TreeItemCollapsibleState.None,
      );
      item.command = {
        title: generator.label,
        command: 'laravelTools.make',
        arguments: [generator.value],
        tooltip: generator.label,
      };
      item.iconPath = new vscode.ThemeIcon('debug-start');
      return item;
    });
    // Refresh the Tree View
    this._onDidChangeTreeData.fire();
  }

  private getWorkspace() {
    this.outputChannel.clear();
    this.outputChannel.appendLine('Checking for VSCode Workspace');
    this.workspacePath = '';
    this.commands = [];
    this.commandOutput = [];
    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders || workspaceFolders.length === 0) {
      throw new Error('No workspace is open.');
    } else {
      const workspacePath = workspaceFolders[0].uri.fsPath;
      const artisanPath = join(workspacePath, 'artisan');

      if (existsSync(artisanPath)) {
        this.workspacePath = workspacePath;
        this.createTerminal();
      } else {
        throw new Error(
          'No artisan file found, have you opened a laravel project?',
        );
      }
    }
  }

  private createTerminal() {
    // Check if the terminal already exists and is not disposed
    if (!this.terminal || this.terminal.exitStatus) {
      // Create a new terminal
      const options: vscode.TerminalOptions = {
        name: 'Artisan Make',
        cwd: this.workspacePath,
      };
      this.terminal = vscode.window.createTerminal(options);
    }
  }

  logArtisanCommand(data: Buffer) {
    const msg = data.toString();
    this.commandOutput.push(msg);
    this.outputChannel.appendLine(msg);
  }

  /**
   * @brief Executes an Artisan command in the terminal or spawns a new process.
   *
   * This method performs the following steps:
   * - Logs the command being run to the output channel.
   * - Executes a shell command to check if the Artisan command has arguments using `exec`.
   * - If the command has arguments:
   *   - Checks if a terminal already exists and is not disposed.
   *   - Creates a new terminal if necessary.
   *   - Sends the Artisan command to the terminal and shows the terminal.
   * - If the command does not have arguments:
   *   - Spawns a new process to run the Artisan command directly.
   *   - Logs the output of the command.
   *   - Displays an error or information message based on the command's exit code.
   *
   * @param command The Artisan command to execute.
   * @param statusBarItem The status bar item to update with the command status.
   */
  make(command: string) {
    try {
      this.outputChannel.appendLine(`Running make ${command}`);
      this.commandOutput = [];
      exec(
        `php -d xdebug.mode=off -d xdebug.start_with_request=no artisan ${command} --help`,
        { cwd: this.workspacePath },
        (error, stdout, stderr) => {
          if (error) {
            this.outputChannel.appendLine(`Error: ${error.message}`);
            return;
          }
          if (stderr) {
            this.outputChannel.appendLine(`Stderr: ${stderr}`);
            return;
          }
          if (stdout.match(/Arguments:/gim)) {
            // If no error, send the command to the terminal
            if (this.terminal.exitStatus) {
              this.createTerminal();
            }
            this.terminal.sendText(
              `php -d xdebug.mode=off -d xdebug.start_with_request=no artisan ${command}`,
            );
            // Show the terminal to the user
            this.terminal.show();
          } else {
            const artisanProcess = spawn(
              'php',
              [
                '-d',
                'xdebug.mode=off',
                '-d',
                'xdebug.start_with_request=no',
                'artisan',
                command,
              ],
              { cwd: this.workspacePath },
            );
            artisanProcess.stdout?.on(
              'data',
              this.logArtisanCommand.bind(this),
            );
            artisanProcess.stdout?.on(
              'data',
              this.logArtisanCommand.bind(this),
            );

            artisanProcess.on('close', (code) => {
              if (code !== 0) {
                vscode.window.showErrorMessage(this.commandOutput.join('\n'));
              } else {
                vscode.window.showInformationMessage(
                  this.commandOutput.join('\n'),
                );
              }
              this.commandOutput = [];
            });
          }
        },
      );
    } catch (error: unknown) {
      if (error instanceof Error) {
        vscode.window.showErrorMessage(error.message);
        this.outputChannel.appendLine(error.message);
      }
    }
  }

  showChannel() {
    this.outputChannel.show();
  }
}

export { ArtisanTreeDataProvider };
