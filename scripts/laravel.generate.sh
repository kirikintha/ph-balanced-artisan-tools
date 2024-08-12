#!/bin/bash

. $(dirname "$0")/base.sh

help=" USAGE $0:
    --project -n [string] the name of the project.
    --destination -d [string] the destination directory.
"

properties=("project=string:required:p" "destination=string:required:d")
process_arguments "${properties[@]}" "$@"

prompt_options='{
    "title": "Choose what you are wanting to generate",
    "size": 10,
    "options": []
}'

generate() {
    project=$(get_value project)
    destination=$(get_value destination)
    if [[ ! -d "$destination/$project" ]]; then
        warn "Error: Project '$project' not found in directory '$destination'."
        exit 1
    fi

    info "Generating Laravel project '$project'."
    cd $destination/$project
    # Capture the output of `php artisan make --help`
    output=$(php artisan make --help 2>&1)

    # # Extract lines that contain the available commands
    commands=$(echo "$output" | grep -Eo 'make:[a-zA-Z0-9-]+' | sort | uniq)

    # # Iterate over the commands and add them to the options array
    # Iterate over the commands and add them to the options array
    for command in $commands; do
        # Trim whitespace from the command
        value=$(echo "$command" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        label=$(echo "$output" | grep "^\s*$value.*" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        label=$(echo "$label" | sed "s/$value//g" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Escape control characters in the label
        label=$(echo "$label" | tr -d '\000-\037')

        # Replace all strings in the label that start and end with []
        label=$(echo "$label" | sed 's/\[[^]]*\]//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Add the command and label to the options array
        prompt_options=$(echo "$prompt_options" | jq --arg label "$label" --arg value "$value" '.options += [{"label": $label, "value": $value}]')
    done

    prompt "$prompt_options"
    action=$(get_selected_value)
    php artisan $action
}

generate
