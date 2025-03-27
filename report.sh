#!/usr/bin/env sh

# Default parameters
OUTPUT_DIR="docs/storage"
SOURCE_DIRS="src"
EXCLUDE_PATHS="interfaces libraries"

# Parse command-line options
while [ $# -gt 0 ]; do
    case "$1" in
    --output=*)
        OUTPUT_DIR="${1#*=}"
        ;;
    --source=*)
        SOURCE_DIRS="${1#*=}"
        ;;
    --exclude=*)
        EXCLUDE_PATHS="${1#*=}"
        ;;
    -h | --help)
        echo "Usage: $0 [OPTIONS]"
        echo "Options:"
        echo "  --output=DIR    Set output directory (default: docs/storage)"
        echo "  --source=DIRS   Set source directories, space-separated (default: src)"
        echo "  --exclude=PATHS Set paths to exclude, space-separated (default: src/interfaces)"
        echo "  -h, --help      Display this help message"
        exit 0
        ;;
    *)
        # For backward compatibility, treat first positional arg as output dir
        if [ -z "$POSITIONAL_ARG" ]; then
            OUTPUT_DIR="$1"
            POSITIONAL_ARG=1
        else
            echo "Unknown option: $1"
            exit 1
        fi
        ;;
    esac
    shift
done

# Function to print messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1"
}

# Function to print error messages
error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >&2
}

log "Starting the storage report generation."
log "Configuration:"
log "  Output directory: $OUTPUT_DIR"
log "  Source directories: $SOURCE_DIRS"
log "  Excluded paths: $EXCLUDE_PATHS"

# Create the output directory if it doesn't exist
if ! mkdir -p "$OUTPUT_DIR"; then
    error "Failed to create output directory: $OUTPUT_DIR"
    exit 1
fi

# Build the find command with all source directories
FIND_CMD=""
for src_dir in $SOURCE_DIRS; do
    # Add each source directory to the find command
    if [ -z "$FIND_CMD" ]; then
        FIND_CMD="find $src_dir"
    else
        FIND_CMD="$FIND_CMD $src_dir"
    fi
done

# Build the exclude arguments for find command
EXCLUDE_ARGS=""
for pattern in $EXCLUDE_PATHS; do
    # Simple glob pattern matching using -path and -o for OR conditions
    if [ -z "$EXCLUDE_ARGS" ]; then
        EXCLUDE_ARGS="-path \"*$pattern*\""
    else
        EXCLUDE_ARGS="$EXCLUDE_ARGS -o -path \"*$pattern*\""
    fi
done

# If we have exclusions, wrap them in a NOT expression
if [ -n "$EXCLUDE_ARGS" ]; then
    EXCLUDE_ARGS="! \\( $EXCLUDE_ARGS \\)"
fi

# Loop through Solidity files and generate storage report
eval "$FIND_CMD -name \"*.sol\" $EXCLUDE_ARGS" | while read -r file; do
    contract_name=$(basename "$file" .sol)

    # Check if the file exists and is readable
    if [ ! -r "$file" ]; then
        error "Cannot read file: $file"
        continue
    fi

    log "Processing contract: $contract_name"

    # Run forge inspect and capture errors
    if ! forge inspect "$contract_name" storage >"$OUTPUT_DIR/$contract_name.txt"; then
        error "Failed to generate storage report for contract: $contract_name"
    else
        log "Storage report generated for contract: $contract_name"
    fi
done
