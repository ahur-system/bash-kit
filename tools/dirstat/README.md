# dirstat

Analyzes directory and filesystem usage with optional recursive tree view.

## Features

- ✅ **Filesystem Analysis** - Shows total, used, and available space
- ✅ **Usage Breakdown** - Displays how much filesystem space a directory uses
- ✅ **Recursive Tree View** - Visual tree of files and directories sorted by size
- ✅ **Human-Readable Sizes** - Automatic B/K/M/G/T formatting
- ✅ **Path Validation** - Graceful error handling for invalid paths
- ✅ **Space-Safe** - Handles directory names with spaces
- ✅ **Standard Tools Only** - Uses only POSIX utilities (df, du, awk, sort, find)

## Installation

```bash
curl -sL https://github.com/ahur-system/bash-kit/raw/main/bkit.sh | sudo bash -s @ install dirstat
```

## Usage

### Basic Directory Analysis
```bash
# Analyze current directory
dirstat

# Analyze specific directory
dirstat /home

# Analyze with full path
dirstat /var/log
```

### Recursive Tree View
```bash
# Show files and directories tree sorted by size
dirstat -r /var/log

# Recursive analysis of current directory
dirstat --recursive .

# Combine path and recursive flag
dirstat -r /home/user/Documents
```

### Help
```bash
dirstat --help
```

## Configuration

No configuration needed. The tool uses these built-in settings:

| Setting | Value | Description |
|---------|-------|-------------|
| `MAX_RECURSIVE_DEPTH` | 2 | Maximum depth for recursive tree view |
| Tree symbols | `├── └──` | Characters used for tree visualization |

## Requirements

- `df` - Filesystem disk space information
- `du` - Directory space usage
- `awk` - Text processing
- `sort` - Sorting utilities
- `find` - File system traversal
- `printf` - Formatted output
- Bash 4.0+

## Output Format

### Basic Mode
```
📊 Filesystem Analysis
════════════════════════════════════════════════════════════════
Path:        /home/user/Documents
Filesystem:  /dev/sda1
Total:       100G
Used:        45G
Available:   50G

📈 Usage Breakdown
════════════════════════════════════════════════════════════════
Path usage:  12.3G of 45G used (27.3%)
```

### Recursive Mode (`-r`)
```
📊 Filesystem Analysis
════════════════════════════════════════════════════════════════
Path:        /var/log
Filesystem:  /dev/sda1
Total:       100G
Used:        45G
Available:   50G

📈 Usage Breakdown
════════════════════════════════════════════════════════════════
Path usage:  2.8G of 45G used (6.2%)

🌳 Directory Tree
════════════════════════════════════════════════════════════════
📂 /var/log
├── 📁 apache2                  1.2G
├── 📁 mysql                    890M
├── 📁 nginx                    456M
├── 📄 kern.log                 234M
└── 📄 auth.log                 78M
```

### Error Handling
```bash
$ dirstat /nonexistent
Error: Path '/nonexistent' does not exist

$ dirstat /root
Error: Path '/root' is not readable
```

## Use Cases

**System Administration:**
- Quickly identify which directories consume the most space
- Analyze filesystem usage before cleanup operations
- Monitor directory growth over time

**Development:**
- Analyze project directory sizes
- Identify large build artifacts or dependencies
- Clean up workspace efficiently

**General Usage:**
- Understand disk space distribution
- Find large directories for cleanup
- Visual directory structure analysis

## Examples

**Find largest files and directories in /var:**
```bash
dirstat -r /var
```

**Check home directory usage:**
```bash
dirstat -r ~
```

**Analyze current project:**
```bash
cd /path/to/project
dirstat -r .
```

**Quick filesystem check:**
```bash
dirstat /
```

## Notes

- Recursive mode shows both files and directories (1 level deep by default)
- Sizes are calculated using `du -sb` for accuracy
- Tree view is sorted by size (largest first)
- Inaccessible directories are silently skipped in recursive mode
- All sizes are displayed in human-readable format (B, K, M, G, T)