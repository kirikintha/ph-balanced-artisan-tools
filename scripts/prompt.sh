#!/bin/bash

# Set trap to ensure cursor visibility on script exit and handle other signals
trap 'ensure_cursor_visible' EXIT SIGINT SIGTERM
trap 'handle_suspend' TSTP

. $(dirname "$0")/alert.sh
. $(dirname "$0")/confirm.sh

declare -a options=()
declare -a activated_states=()
valid=false
current_choice=0
size=10
title="Select an option"
allow_multiple_selections=false

# Function to ensure cursor visibility
ensure_cursor_visible() {
    tput cnorm
}

# Function to handle script suspension (TSTP)
handle_suspend() {
    ensure_cursor_visible # Make the cursor visible before suspending
    exit
}

prompt() {
    local json_input="$1"

    title=$(echo "$json_input" | jq -r '.title')
    size=$(echo "$json_input" | jq -r '.size')

    local length=$(echo "$json_input" | jq '.options | length')
    options=()
    for ((i = 0; i < length; i++)); do
        options+=("$(echo "$json_input" | jq -c ".options[$i]")")
    done
    current_choice=0
    # Initialize activated_states dynamically based on the number of options
    activated_states=()
    for option in "${options[@]}"; do
        activated_states+=("0")
    done
    display_options
    read_input
}

# Function to display options, highlighting the current choice
display_options() {
    local display=$(info "$title\n") # Assuming info outputs a string with a newline
    local window_size=$size
    local total_options=${#options[@]}
    local half_window=$((window_size / 2))

    # Calculate the start and end of the window
    local window_start=$((current_choice - half_window))
    local window_end=$((current_choice + half_window))

    # Adjust the window if it goes out of bounds
    if [[ window_start -lt 0 ]]; then
        window_end=$((window_end - window_start))
        window_start=0
    elif [[ window_end -ge total_options ]]; then
        window_start=$((window_start - (window_end - total_options + 1)))
        window_end=$((total_options - 1))
    fi

    # Ensure window_start is not negative
    window_start=$((window_start < 0 ? 0 : window_start))
    for ((i = window_start; i <= window_end; i++)); do
        # Split the option into label and value
        label=$(echo "${options[$i]}" | jq -r '.label')
        if [[ "${activated_states[$i]}" == "1" ]]; then
            activation_indicator="${Green}●${Color_Off}"
        else
            activation_indicator="○"
        fi
        if [[ "$i" == "$current_choice" ]]; then
            # Highlight the current choice
            display+="$activation_indicator \033[7m${label}\033[27m\n"
        else
            # Non-selected options
            display+="$activation_indicator ${label}\n"
        fi
    done
    # Clear the screen and move the cursor to the top-left corner
    printf "\033[2J\033[H"
    # Draw the new content from the display variable
    printf "$display"
}

up_arrow() {
    if [[ "$current_choice" -gt 0 ]]; then
        ((current_choice--))
    else
        current_choice=$((${#options[@]} - 1))
    fi
}

down_arrow() {
    if [[ "$current_choice" -lt $((${#options[@]} - 1)) ]]; then
        ((current_choice++))
    else
        current_choice=0
    fi
}

escape() {
    bailout "Are you sure you want to exit?"
    ensure_cursor_visible
}

space_bar() {
    if [[ "${activated_states[$current_choice]}" == "1" ]]; then
        activated_states[$current_choice]=0
    else
        if [[ "$allow_multiple_selections" == false ]]; then
            # Clear all activated states
            for i in "${!activated_states[@]}"; do
                activated_states[$i]=0
            done
        fi
        activated_states[$current_choice]=1
    fi
}

finish() {
    if [[ "$valid" == false ]]; then
        warn "Please select a valid option before proceeding."
        sleep 1.5
    else
        ensure_cursor_visible
        label=$(echo "${options[$current_choice]}" | jq -r '.label')
        confirm "Do you want to select $label?"
        clear
        info "You selected: $label"
        break
    fi
}

validate() {
    if [[ " ${activated_states[@]} " =~ " 1 " ]]; then
        valid=true
    else
        valid=false
    fi
}

# Function to read key inputs
read_input() {
    tput civis
    local char
    local string
    local esc=$'\e'
    local up=$'\e[A'
    local down=$'\e[B'
    local clear_line=$'\r\e[K'
    local space=$' '
    local enter=$''
    prompt="Use arrow keys to navigate, spacebar to toggle and enter to select"
    while IFS="" read -r -n1 -s char; do
        if [[ "$char" == "$esc" ]]; then
            read -r -n2 -s char # Read the next two characters of the sequence
            char="$esc$char"    # Prepend the escape character to form the full sequence
        fi
        case "$char" in
        "$up") up_arrow ;;
        "$down") down_arrow ;;
        "$space") space_bar ;;
        "$enter") finish ;;
        *) escape ;;
        esac
        validate
        display_options
    done
}

get_selected_value() {
    value=$(echo "${options[$current_choice]}" | jq -r '.value')
    echo "$value"
}
