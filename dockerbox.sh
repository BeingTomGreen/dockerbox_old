#!/bin/bash

DOCKERBOX_ROOT="/home/tom/dockerbox"

# Ensure DOCKERBOX_ROOT dir exists
if [ ! -d "$DOCKERBOX_ROOT" ]; then
  echo -e "${RED}Error:${NC} dockerbox directory not found ($DOCKERBOX_ROOT)."
  exit 0
fi

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ORANGE='\033[38;5;208m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function show_help() {
    echo "Welcome to dockerbox!"
    echo
    echo "Usage: ./dockerbox.sh <command> [options]"
    echo
    echo "Commands:"
    echo "  create [service_name]       Create a new service."
    echo "  start [service_name]        Start all services or a specific service."
    echo "  stop [service_name]         Start all services or a specific service."
    echo "  validate [service_name]     Ensure that all services, or a specified service are valid."
}

# Hanldes creation of a new service
function create_service() {
    local service_name="$1"
    local service_dir="$DOCKERBOX_ROOT/$service_name"

    # Check if the service directory already exists
    if [ -d "$service_dir" ]; then
        echo -e "${RED}Error:${NC} Service '$service_name' already exists."
        return 1
    fi

    # Create the service directory
    mkdir -p "$service_dir"

    # Create the required directories/files
    echo "version: '3.8'" > "$service_dir/docker-compose.yml"
    echo "" >> "$service_dir/docker-compose.yml"
    echo "services:" >> "$service_dir/docker-compose.yml"

    # Create the volumes folder
    mkdir -p "$service_dir/volumes"

    # Create the .gitignore file in the volumes folder
    echo "*" > "$service_dir/volumes/.gitignore"
    echo "!.gitignore" >> "$service_dir/volumes/.gitignore"

    # Create the backup dir
    mkdir -p "$service_dir/backup"

    # Copy the .gitignore from volumes to backup
    cp "$service_dir/volumes/.gitignore" "$service_dir/backup"

    echo "Service '$service_name' created successfully."
    return 0
}

# Ensures that a specified service is valid
function validate_service() {
    local service_name="$1"
    local service_dir="$DOCKERBOX_ROOT/$service_name"
    local compose_file_path="$service_dir/docker-compose.yml"
    local volumes_dir="$service_dir/volumes"
    local backups_dir="$service_dir/backups"
    local quiet=false
    local fix=false

    # Parse flags
    while [ $# -gt 0 ]; do
        case "$1" in
            -f|--fix)
                fix=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    # Check if the service directory exists
    if [ ! -d "$service_dir" ]; then
        if [ "$fix" = true ]; then
            mkdir -p "$service_dir"

            if [ "$quiet" != true ]; then
                echo -e "${BLUE}Service directory for '$service_name' created.${NC}"
            fi
        else
            if [ "$quiet" != true ]; then
                echo -e "${RED}Error:${NC} Service '$service_name' not found."
            fi
            return 1
        fi
    fi

    # Check if docker-compose.yml exists
    if [ ! -f "$compose_file_path" ]; then
        if [ "$fix" = true ]; then
            {
              echo "---"
              echo ""
              echo "version: \"3.8\""
              echo "services:"
              echo "$service_name:"
              echo "    image: "
              echo "    container_name: $service_name"
            } >> "$compose_file_path"

            if [ "$quiet" != true ]; then
                echo -e "${BLUE}docker-compose.yml for '$service_name' created.${NC}"
            fi
        else
            if [ "$quiet" != true ]; then
                echo -e "${RED}Error:${NC} docker-compose.yml not found for service '$service_name'."
            fi

            return 1
        fi
    fi

    # Check if the volumes directory exists
    if [ ! -d "$volumes_dir" ]; then
        if [ "$fix" = true ]; then
            mkdir -p "$volumes_dir"
            echo -e "${BLUE}Volumes directory for '$service_name' created.${NC}"
        else
            echo -e "${RED}Error:${NC} Volumes directory for '$service_name' not found."
            return 1
        fi
    fi

    # Check if the backups directory exists
    if [ ! -d "$backups_dir" ]; then
        if [ "$fix" = true ]; then
            mkdir -p "$backups_dir"
            echo -e "${BLUE}Backups directory for '$service_name' created.${NC}"
        else
            echo -e "${RED}Error:${NC} Backups directory for '$service_name' not found."
            return 1
        fi
    fi

    if [ "$quiet" != true ]; then
        echo -e "${GREEN}Valid:${NC} '$service_name'."
    fi

    return 0
}

# Validates all services
function validate_all_services() {
    local quiet_flag="$1"
    local fix_flag="$2"

    # Loop through each service directory
    for service_dir in "$DOCKERBOX_ROOT"/*/; do
        service_name=$(basename "$service_dir")
        validate_service "$service_name" "$quiet_flag" "$fix_flag"
    done
}

# Starts a specified service
function start_service() {
    local service_name="$1"
    local compose_file="$DOCKERBOX_ROOT/$service_name/docker-compose.yml"

    echo -e "${BLUE}Starting $service_name...${NC}"

    if validate_service "$service_name" -q; then
        # Check if the service is already running
        if [ -n "$(docker compose -f "$compose_file" ps -q)" ]; then
            echo -e "${ORANGE}'$service_name' is already running.${NC}"
        else
            # Try and start the docker container
            if docker compose -f "$compose_file" --progress quiet up -d; then
                echo -e "${GREEN}'$service_name' started.${NC}"
            else
                echo -e "${RED}Error:${NC} Failed to start $service_name"
            fi
        fi
    fi
}

# Starts all of the services
function start_all_services() {
    # Loop through each service directory
    for service_dir in "$DOCKERBOX_ROOT"/*/; do
        service_name=$(basename "$service_dir")
        start_service "$service_name"
    done
}

# Stops a specified service
function stop_service() {
    local service_name="$1"
    local compose_file="$DOCKERBOX_ROOT/$service_name/docker-compose.yml"

    echo -e "${BLUE}Stopping $service_name...${NC}"

    if validate_service "$service_name" -q; then
        # Check if the service is running
        if [ -n "$(docker compose -f "$compose_file" ps -q)" ]; then
            # Try and stop the docker container
            if docker compose -f "$compose_file" --progress quiet down; then
                echo -e "${GREEN}'$service_name' stopped.${NC}"
            else
                echo -e "${RED}Error:${NC} Failed stop $service_name"
            fi
        else
            echo -e "${ORANGE}'$service_name' is not running.${NC}"
        fi
    fi
}

# Stops all of the services
function stop_all_services() {
    # Loop through each service directory
    for service_dir in "$DOCKERBOX_ROOT"/*/; do
        service_name=$(basename "$service_dir")
        stop_service "$service_name"
    done
}

########################
## Core functionality ##
########################

# handles dockerbox start
function start() {
    # If a specific service was provided
    if [ -n "$2" ]; then
        service_name="$2"
        start_service "$service_name"
    # Start all the things
    else
        echo "Starting all services"
        start_all_services
    fi
}

# handles dockerbox stop
function stop() {
    # If a specific service was provided
    if [ -n "$2" ]; then
        service_name="$2"
        stop_service "$service_name"
    # stop all the things
    else
        stop_all_services
    fi
}

# handles dockerbox validate
function validate() {
    local fix_flag=false
    local quiet_flag=false

    # Process command-line options
    while [ $# -gt 0 ]; do
        case "$1" in
            -f|--fix)
                fix_flag=true
                shift
                ;;
            -q|--quiet)
                quiet_flag=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    # If a specific service was provided
    if [ -n "$1" ]; then
        service_name="$1"
        validate_service "$service_name" "$quiet_flag" "$fix_flag"
    # Validate all services
    else
        validate_all_services "$quiet_flag" "$fix_flag"
    fi
}

# handles dockerbox create
function create() {
    if [ -n "$2" ]; then
        service_name="$2"
        create_service "$service_name"
    else
        echo -e "${RED}Error:${NC} Usage: ./dockerbox.sh create <service_name>"
        return 1
    fi
}

# Main script logic
case "$1" in
    "create")
        create "$@"
        ;;
    "start")
        start "$@"
        ;;
    "stop")
        stop "$@"
        ;;
    "validate")
        validate "$@"
        ;;
    *)
      show_help
      ;;
esac