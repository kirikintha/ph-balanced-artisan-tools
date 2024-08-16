#!/bin/bash
set -e
npm install --include=dev
npm audit --omit=dev
echo "Linting source"
npm run lint
echo "Packagins source"
npm run vscode:package
echo "Publishing source"
npm run vscode:publish
