#!/bin/bash

# Function to display usage information
function display_usage() {
    echo "Usage: $0 <option> [parallel]"
    echo "where <option> can be one of the following:"
    echo "  prectuner/scalehls/all   - Execute with 'prectuner/scalehls/all RATE=' option"
    echo "  [parallel option] - 'p', 'paral', or 'parallel' will enable parallel execution."
}

# Function to handle Ctrl+C (SIGINT) and propagate to background processes
function handle_sigint() {
    echo -e "\nCaught SIGINT (Ctrl+C). Propagating signal to background processes..."
    kill $(jobs -p) 2>/dev/null
    exit 1
}

# Trap Ctrl+C (SIGINT) signal to call handle_sigint function
trap handle_sigint SIGINT

# Store COMMAND_TYPE (prectuner/scalehls/all) for consistent logging
COMMAND_TYPE=""

# Check if the first argument is provided
if [ -z "$1" ]; then
    echo "No option provided. Please enter an option:"
    display_usage
    read -p "Enter 'prectuner' or 'scalehls' or 'all': " USER_INPUT
    if [ "$USER_INPUT" != "prectuner" ] && [ "$USER_INPUT" != "scalehls" ] && [ "$USER_INPUT" != "all" ]; then
        echo "Invalid input. Exiting."
        exit 1
    fi
    COMMAND_TYPE="$USER_INPUT"
    BASE_OPTION="${USER_INPUT} RATE="
else
    if [ "$1" == "prectuner" ]; then
        COMMAND_TYPE="prectuner"
        BASE_OPTION="prectuner RATE="
    elif [ "$1" == "scalehls" ]; then
        COMMAND_TYPE="scalehls"
        BASE_OPTION="scalehls RATE="
    elif [ "$1" == "all" ]; then
        COMMAND_TYPE="all"
        BASE_OPTION="all RATE="
    else
        echo "Invalid option '$1'. Exiting."
        display_usage
        exit 1
    fi
fi

# Get the script's directory
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Create timestamp once at the start
START_TIMESTAMP=$(date +%Y%m%d%H)
LOG_DIR="____tempfile_logs_$START_TIMESTAMP"

# Change to the 'utilities' subdirectory
cd ${SCRIPT_DIR}/utilities
echo "Changed to $(pwd) and running clean.pl..."
perl makefile-gen.pl ../ -cfg
perl clean.pl ../
perl makefile-gen.pl ../ -cfg

# Create log dir with absolute path
LOG_DIR_FULL="${SCRIPT_DIR}/utilities/${LOG_DIR}"
mkdir -p "$LOG_DIR_FULL"

# Define RATE values (modified to include base case without RATE)
# RATE_VALUES=(-1 0 5 10 15 21 26 31 36 42 47 52 57 63 68 73 78 84 89 94 100)
RATE_VALUES=(-1 0 15 31 52 73 94 100)

echo -e "\nStarting execution with the following options:"
echo -e "Command type: $COMMAND_TYPE"
echo -e "Base option: $BASE_OPTION"
echo -e "Rate values to iterate: ${RATE_VALUES[@]}"
echo -e "Parallel execution: ${2}"
echo -e "Log directory: $LOG_DIR_FULL\n"

# Loop through RATE values and execute commands
for RATE in "${RATE_VALUES[@]}"; do
    # Reset the Makefile to default
    perl makefile-gen.pl ../

    if [ $RATE -eq -1 ]; then
        # For -1, use base option without RATE
        OPTION="${COMMAND_TYPE}"
    else
        # For other values, append RATE as usual
        OPTION="${BASE_OPTION}${RATE}"
    fi
    
    # Generate a dynamic log file name based on the option and rate
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    LOG_FILE="${LOG_DIR_FULL}/${COMMAND_TYPE}_${2}_rate_${RATE}_${TIMESTAMP}.log"

    # Start the process and capture the PID
    perl run-all.pl ../ "$OPTION" "$2" > "$LOG_FILE" &  
    PID=$!

    # Initialize timer
    SECONDS=0
    
    # Dynamic progress update with timer
    while kill -0 $PID 2>/dev/null; do
        ELAPSED=$SECONDS
        MINS=$((ELAPSED / 60))
        SECS=$((ELAPSED % 60))
        echo -ne "\rExecuting with option: $OPTION $2 (PID: $PID), Runtime: ${MINS}m ${SECS}s..."
        sleep 1
    done
done

# Final message with log directory location
echo -e "\rAll executions completed."
