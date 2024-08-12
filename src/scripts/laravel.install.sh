#!/bin/bash

# Arguments:
#   name

# Options:
#       --dev                        Installs the latest "development" release
#       --git                        Initialize a Git repository
#       --branch=BRANCH              The branch that should be created for a new repository [default: "main"]
#       --github[=GITHUB]            Create a new repository on GitHub [default: false]
#       --organization=ORGANIZATION  The GitHub organization to create the new repository for
#       --database=DATABASE          The database driver your application will use
#       --stack[=STACK]              The Breeze / Jetstream stack that should be installed
#       --breeze                     Installs the Laravel Breeze scaffolding
#       --jet                        Installs the Laravel Jetstream scaffolding
#       --dark                       Indicate whether Breeze or Jetstream should be scaffolded with dark mode support
#       --typescript                 Indicate whether Breeze should be scaffolded with TypeScript support
#       --ssr                        Indicate whether Breeze or Jetstream should be scaffolded with Inertia SSR support
#       --api                        Indicates whether Jetstream should be scaffolded with API support
#       --teams                      Indicates whether Jetstream should be scaffolded with team support
#       --verification               Indicates whether Jetstream should be scaffolded with email verification support
#       --pest                       Installs the Pest testing framework
#       --phpunit                    Installs the PHPUnit testing framework
#       --prompt-breeze              Issues a prompt to determine if Breeze should be installed (Deprecated)
#       --prompt-jetstream           Issues a prompt to determine if Jetstream should be installed (Deprecated)
#   -f, --force                      Forces install even if the directory already exists
#   -h, --help                       Display help for the given command. When no command is given display help for the list command
#   -q, --quiet                      Do not output any message
#   -V, --version                    Display this application version
#       --ansi|--no-ansi             Force (or disable --no-ansi) ANSI output
#   -n, --no-interaction             Do not ask any interactive question
#   -v|vv|vvv, --verbose             Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug

. $(dirname "$0")/base.sh

supported_databases=("sqlite" "sqlsvr" "pgsql")

# Check if Laravel is installed
if ! command -v laravel &>/dev/null; then
    warn "Laravel is not installed. Please install Composer and Laravel before proceeding."
    info <<EOF
To install composer, run the following command:
\t brew install composer
You can install Laravel by running the following command:
\t composer global require laravel/installer
\t export PATH="\$PATH:\$HOME/.composer/vendor/bin" or similar for your operating system
EOF
    exit 1
fi

help=" USAGE $0:
    --project -n [string] the name of the project.
    --destination -d [string] the destination directory.
    --database -db [string] the database to use. Valid values are 'sqlite', 'sqlsvr', 'pgsql'.
"

properties=("project=string:required:n" "database=string:required:db", "destination=string:required:d")
process_arguments "${properties[@]}" "$@"

workspace='
{
    "folders": [
        {
            "path": "."
        }
    ]
}'

install() {
    project=$(get_value project)
    database=$(get_value database)
    destination=$(get_value destination)

    if [[ ! " ${supported_databases[@]} " =~ " ${database} " ]]; then
        warn "Error: Unsupported database '$database'."
        info "Supported databases are: ${supported_databasses[@]}."
        exit 1
    fi

    info "Installing Laravel project '$project' with database '$database'."
    mkdir -p $destination
    cd $destination
    laravel new $project --database=$database --git --jet --stack inertia --teams --dark --ssr --api --verification --phpunit
    # Create the workspace file
    echo "${workspace}" >$project.code-workspace
}

install
