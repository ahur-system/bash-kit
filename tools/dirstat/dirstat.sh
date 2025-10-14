#!/usr/bin/env bash
# bash-kit tool: dirstat
# Analyzes directory and filesystem usage with optional recursive tree view
#
# Part of bash-kit: https://github.com/alikhaleghi/bash-kit
# Requires: df, du, awk, sort, find, printf

set -euo pipefail

# --- CONFIG ---
MAX_RECURSIVE_DEPTH=2
TREE_SYMBOLS=("├──" "└──" "│  " "   ")
# --- END CONFIG ---

# --- UTILITY FUNCTIONS ---
show_usage() {
  echo "Usage: dirstat [OPTIONS] [PATH]"
  echo
  echo "Analyze directory and filesystem usage"
  echo
  echo "OPTIONS:"
  echo "  -r, --recursive    Show recursive tree view of subdirectories"
  echo "  -h, --help         Show this help message"
  echo
  echo "ARGUMENTS:"
  echo "  PATH              Directory to analyze (default: current directory)"
  echo
  echo "Examples:"
  echo "  dirstat /home"
  echo "  dirstat -r /var/log"
  echo "  dirstat --recursive ."
}

# Convert bytes to human readable format
human_readable() {
  local bytes="$1"
  awk -v bytes="$bytes" '
  BEGIN {
    units[1]="B"; units[1024]="K"; units[1024^2]="M"; units[1024^3]="G"; units[1024^4]="T"
    for (i=1024^4; i>=1; i/=1024) {
      if (bytes >= i) {
        printf "%.1f%s", bytes/i, units[i]
        break
      }
    }
    if (bytes == 0) printf "0B"
  }'
}

# Get filesystem information for a path
get_filesystem_info() {
  local target_path="$1"
  df -h "$target_path" | awk 'NR==2 {
    print $1 "|" $2 "|" $3 "|" $4 "|" $5
  }'
}

# Get directory size in bytes
get_dir_size_bytes() {
  local path="$1"
  du -sb "$path" 2>/dev/null | awk '{print $1}' || echo "0"
}

# Calculate percentage
calc_percentage() {
  local part="$1"
  local total="$2"
  awk -v part="$part" -v total="$total" '
  BEGIN {
    if (total == 0) print "0.0"
    else printf "%.1f", (part/total)*100
  }'
}

# Display filesystem header
show_filesystem_header() {
  local target_path="$1"
  local resolved_path
  resolved_path=$(realpath "$target_path")

  echo "📊 Filesystem Analysis"
  echo "════════════════════════════════════════════════════════════════"

  # Get filesystem info
  local fs_info
  fs_info=$(get_filesystem_info "$resolved_path")
  IFS='|' read -r device total used available usage_percent <<< "$fs_info"

  printf "Path:        %s\n" "$resolved_path"
  printf "Filesystem:  %s\n" "$device"
  printf "Total:       %s\n" "$total"
  printf "Used:        %s\n" "$used"
  printf "Available:   %s\n" "$available"
  echo
}

# Show usage breakdown
show_usage_breakdown() {
  local target_path="$1"

  echo "📈 Usage Breakdown"
  echo "════════════════════════════════════════════════════════════════"

  # Get directory size and filesystem used space
  local dir_size_bytes used_space_kb
  dir_size_bytes=$(get_dir_size_bytes "$target_path")
  used_space_kb=$(df "$target_path" | awk 'NR==2 {print $3}')

  # Convert to consistent units (bytes)
  local used_space_bytes=$((used_space_kb * 1024))

  local dir_size_human used_size_human percentage
  dir_size_human=$(human_readable "$dir_size_bytes")
  used_size_human=$(human_readable "$used_space_bytes")
  percentage=$(calc_percentage "$dir_size_bytes" "$used_space_bytes")

  printf "Path usage:  %s of %s used (%s%%)\n" "$dir_size_human" "$used_size_human" "$percentage"
  echo
}

# Generate tree structure for recursive mode
show_recursive_tree() {
  local target_path="$1"
  local resolved_path
  resolved_path=$(realpath "$target_path")

  echo "🌳 Directory Tree"
  echo "════════════════════════════════════════════════════════════════"

  if [ ! -d "$resolved_path" ]; then
    echo "Error: Not a directory"
    return 1
  fi

  echo "📂 $resolved_path"

  # Get subdirectories with sizes, sort by size (largest first)
  local temp_file
  temp_file=$(mktemp)

  # Find direct subdirectories and get their sizes
  find "$resolved_path" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | \
  while IFS= read -r -d '' subdir; do
    if [ -r "$subdir" ]; then
      size_bytes=$(get_dir_size_bytes "$subdir")
      basename_dir=$(basename "$subdir")
      echo "$size_bytes|$basename_dir"
    fi
  done | sort -t'|' -k1 -nr > "$temp_file"

  # Display the tree
  local line_count
  line_count=$(wc -l < "$temp_file")
  local current_line=1

  while IFS='|' read -r size_bytes dir_name; do
    if [ "$current_line" -eq "$line_count" ]; then
      tree_char="└──"
    else
      tree_char="├──"
    fi

    size_human=$(human_readable "$size_bytes")
    printf "%s %-30s %s\n" "$tree_char" "$dir_name" "$size_human"

    ((current_line++))
  done < "$temp_file"

  rm -f "$temp_file"

  if [ "$line_count" -eq 0 ]; then
    echo "└── (no subdirectories found)"
  fi
  echo
}

# Main analysis function
analyze_directory() {
  local target_path="$1"
  local recursive="$2"

  # Verify path exists and is accessible
  if [ ! -e "$target_path" ]; then
    echo "Error: Path '$target_path' does not exist" >&2
    exit 1
  fi

  if [ ! -r "$target_path" ]; then
    echo "Error: Path '$target_path' is not readable" >&2
    exit 1
  fi

  # Show filesystem header
  show_filesystem_header "$target_path"

  # Show usage breakdown
  show_usage_breakdown "$target_path"

  # Show recursive tree if requested
  if [ "$recursive" = "true" ]; then
    show_recursive_tree "$target_path"
  fi
}

# --- ARGUMENT HANDLING ---
parse_arguments() {
  local recursive="false"
  local target_path="."

  while [ $# -gt 0 ]; do
    case "$1" in
      -r|--recursive)
        recursive="true"
        shift
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      -*)
        echo "Error: Unknown option '$1'" >&2
        show_usage >&2
        exit 1
        ;;
      *)
        if [ "$target_path" != "." ]; then
          echo "Error: Multiple paths specified" >&2
          show_usage >&2
          exit 1
        fi
        target_path="$1"
        shift
        ;;
    esac
  done

  # Call main analysis function
  analyze_directory "$target_path" "$recursive"
}

# --- MAIN EXECUTION ---
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  parse_arguments "$@"
fi
