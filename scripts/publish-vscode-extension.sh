#!/bin/bash
set -e
npm install --include=dev
npm audit --omit=dev
npm run lint
npm run vscode:package
npm run vscode:publish
