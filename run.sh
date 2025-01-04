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
    # Propagate SIGINT to all background processes (using jobs)
    kill $(jobs -p) 2>/dev/null
    # Terminate the script after propagating the signal
    exit 1
}

# Trap Ctrl+C (SIGINT) signal to call handle_sigint function
trap handle_sigint SIGINT

# Check if the first argument is provided
if [ -z "$1" ]; then
    # Prompt for input if no argument is passed
    echo "No option provided. Please enter an option:"
    display_usage
    read -p "Enter 'fpga' or 'all': " USER_INPUT
    if [ "$USER_INPUT" != "fpga" ] && [ "$USER_INPUT" != "all" ]; then
        echo "Invalid input. Exiting."
        exit 1
    fi
    BASE_OPTION="${USER_INPUT} RATE="
else
    # Use the provided argument if valid
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
perl makefile-gen.pl ../ -cfg
mkdir -p ____tempfile_logs

# Define RATE values
RATE_VALUES=(5 25 50 75 95)

# Display a neat header for execution info
echo -e "Starting execution with the following options:"
echo -e "Option: $BASE_OPTION"
echo -e "Rate values to iterate: ${RATE_VALUES[@]}"
echo -e "Parallel execution: ${2} .\n"

# Loop through RATE values and execute commands
for RATE in "${RATE_VALUES[@]}"; do
    OPTION="${BASE_OPTION}${RATE}"
    
    # Generate a unique log file name
    LOG_FILE="____tempfile_logs/__amp_${RATE}_$(date +%Y%m%d%H%M%S).log"

    # Display dynamic progress with carriage return (\r) to overwrite the line
    echo -n "Executing with option: $OPTION $2... "

    # Pass the second argument directly to the perl command, if provided
    perl run-all.pl ../ "$OPTION" "$2" > "$LOG_FILE" &  # Run the command in the background

    # Store the process ID for later termination if needed
    PID=$!

    # Dynamic progress: continuously update the same line with the current RATE value
    while kill -0 $PID 2>/dev/null; do
        # Use \r to return to the beginning of the line and overwrite
        echo -ne "\rExecuting with option: $OPTION... Progress: $RATE"
        sleep 0.5  # Update every half second (adjustable)
    done

    # Once the process finishes, print the result
    echo -e "\rDone! Process ID $PID finished. Output is being logged to: $(pwd)/$LOG_FILE"
done

echo -e "\nAll executions completed."