#!/bin/bash

confirm() {
  message=$1
  read -p "$(info "$message") [yes|No]" CONFIRM
  case "$CONFIRM" in
  y | Y | yes) ;;
  n | N | no)
    exit 1
    ;;
  *)
    failure "Invalid choice entered, the valid choices are y, Y, yes, n, N, no."
    exit 1
    ;;
  esac
}

bailout() {
  message=$1
  read -p "$(info "$message") [yes|No]" CONFIRM
  case "$CONFIRM" in
  y | Y | yes) exit 1 ;;
  n | N | no) ;;
  *)
    failure "Invalid choice entered, the valid choices are y, Y, yes, n, N, no."
    exit 1
    ;;
  esac
}
