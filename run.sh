#!/bin/bash

# Function to display usage information
function display_usage() {
    echo "Usage: $0 <option> [parallel]"
    echo "where <option> can be one of the following:"
    echo "  fpga   - Execute with 'fpga RATE=' option"
    echo "  all    - Execute with 'all RATE=' option"
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

# Check if the first argument is provided
if [ -z "$1" ]; then
    echo "No option provided. Please enter an option:"
    display_usage
    read -p "Enter 'fpga' or 'all': " USER_INPUT
    if [ "$USER_INPUT" != "fpga" ] && [ "$USER_INPUT" != "all" ]; then
        echo "Invalid input. Exiting."
        exit 1
    fi
    BASE_OPTION="${USER_INPUT} RATE="
else
    if [ "$1" == "fpga" ]; then
        BASE_OPTION="fpga RATE="
    elif [ "$1" == "all" ]; then
        BASE_OPTION="all RATE="
    else
        echo "Invalid option '$1'. Exiting."
        display_usage
        exit 1
    fi
fi

# Get the script's directory
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Change to the 'utilities' subdirectory
cd ${SCRIPT_DIR}/utilities
echo "Changed to $(pwd)"
# perl clean.pl ../
perl makefile-gen.pl ../
mkdir -p ____tempfile_logs

# Define RATE values
RATE_VALUES=(0 1 12 25 37 50 62 75 87 99 100)

echo -e "\nStarting execution with the following options:"
echo -e "Option: $BASE_OPTION"
echo -e "Rate values to iterate: ${RATE_VALUES[@]}"
echo -e "Parallel execution: ${2} .\n"

# Loop through RATE values and execute commands
for RATE in "${RATE_VALUES[@]}"; do
    OPTION="${BASE_OPTION}${RATE}"
    
    # Generate a dynamic log file name based on the option and rate
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    LOG_FILE="____tempfile_logs/${1}_${2}_rate_${RATE}_${TIMESTAMP}.log"

    # Start the process and capture the PID
    perl run-all.pl ../ "$OPTION" "$2" > "$LOG_FILE" &  
    PID=$!

    # Dynamic progress update
    while kill -0 $PID 2>/dev/null; do
        echo -ne "\rExecuting with option: $OPTION $2 (PID: $PID)... "
        sleep 1
    done
done

# Final message
echo -e "\rAll executions completed.                                "