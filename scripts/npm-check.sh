#!/bin/bash

set -e
ncu -u
npm-check --skip-unused
npm install
npm audit fix --omit=dev
