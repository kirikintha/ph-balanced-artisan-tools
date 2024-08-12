#!/bin/bash

. $(dirname "$0")/base.sh

help=" USAGE $0:
    --project -n [string] the name of the project.
    --destination -d [string] the destination directory.
"

properties=("project=string:required:p" "destination=string:required:d")
process_arguments "${properties[@]}" "$@"

stop() {
    project=$(get_value project)
    destination=$(get_value destination)
    if [[ ! -d "$destination/$project" ]]; then
        warn "Error: Project '$project' not found in directory '$destination'."
        exit 1
    fi
    lsof -i :9003 | grep LISTEN | awk '{print $2}' | xargs kill
    lsof -t -i:8000 | xargs -r kill
    info "Stopped Laravel project '$project'."
}

stop
