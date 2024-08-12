#!/bin/bash

function usage() {
    echo "$help"
}

function check_missing() {
    local missing_properties=()
    for property in "${properties[@]}"; do
        # Ignore booleans as they evaluate to either true or false automatically
        if [[ $property =~ ^([a-z-]{0,24}=)(string|integer):(optional|required)(:[a-z]{1,3})? ]]; then
            IFS='=' read -r key value <<<"$property"
            IFS=':' read -r datatype requirement shorthand <<<"$value"
            # Check if the property is required and if it is not a boolean
            # flagged required boolean properties are set to true by default
            if [[ $requirement == "required" ]]; then
                k=${key// /_}
                k=${k//-/_}
                k=$(echo "$k" | tr '[:upper:]' '[:lower:]') # convert to lowercase
                v=$(get_value "$k")
                # Check for shorthand if key value is not found
                if [[ -z "$v" && -n "$shorthand" ]]; then
                    shorthand_key=${shorthand// /_}
                    shorthand_key=${shorthand_key//-/_}
                    shorthand_key=$(echo "$shorthand_key" | tr '[:upper:]' '[:lower:]') # convert to lowercase
                    v=$(get_value "$shorthand_key")
                fi
                if [[ -z "$v" ]]; then
                    missing_properties+=("$key")
                fi
            fi
        fi
    done
    if [[ ${#missing_properties[@]} -gt 0 ]]; then
        warn $0
        warn "The following properties are required:"
        for property in "${missing_properties[@]}"; do
            warn "  * $property"
        done
        exit 1
    fi
}

function process_arguments() {
    properties=("help=usage:optional:h" "$@")
    missing_properties=()
    values=()

    # Check for help flag before processing other arguments
    for arg in "$@"; do
        if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            usage
            exit 0
        fi
    done

    while [[ "$#" -gt 0 ]]; do
        arg=${1#--}
        arg=${arg#-}

        # Skip if arg matches any property
        if [[ "${arg}" =~ ^-+ && " ${properties[@]} " =~ " ${arg} " ]]; then
            shift
            continue
        fi

        # Match the arg to the properties
        for property in "${properties[@]}"; do
            IFS='=' read -r key value <<<"$property"
            IFS=':' read -r datatype requirement shorthand <<<"$value"
            arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr '-' '_')
            if [[ $key == $arg || $shorthand == $arg ]]; then
                case $datatype in
                boolean)
                    # Flagged boolean properties are set to true by default
                    if [[ $requirement == "required" ]]; then
                        if [[ "$2" =~ ^(yes|Y|y)$ ]] || [[ -z "$2" ]] || [[ "$2" =~ ^- ]]; then
                            values+=("$key:true")
                        else
                            values+=("$key:false")
                        fi
                    else
                        if [[ "$2" =~ ^(yes|Y|y)$ ]]; then
                            values+=("$key:true")
                        else
                            values+=("$key:false")
                        fi
                    fi
                    ;;
                integer)
                    if [[ $2 =~ ^-?[0-9]+$ ]]; then
                        values+=("$key:$2")
                    fi
                    ;;
                string)
                    if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                        values+=("$key:$2")
                    fi
                    ;;
                esac
            fi
        done

        shift
    done

    check_missing

    properties=()

}

function get_value() {
    local find=$1
    for i in "${!values[@]}"; do
        IFS=':' read -r key value <<<"${values[$i]}"
        if [[ $key == $find ]]; then
            echo $value
            return
        fi
    done
}
