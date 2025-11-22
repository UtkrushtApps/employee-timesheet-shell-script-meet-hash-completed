#!/bin/bash

# Accept input CSV file as first argument
INPUT_FILE="${1}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print error messages
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to print info messages
print_info() {
    echo -e "${BLUE}$1${NC}"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Function to show usage
show_usage() {
    cat << EOF
Employee Timesheet Processing Script

USAGE:
    $0 <timesheet.csv>

DESCRIPTION:
    Processes employee timesheet data from a CSV file and generates a summary report.
    
    The CSV file must have the following header:
        EmployeeID,Date,HoursWorked,ProjectName
    
    The script will:
    - Calculate total hours worked per employee
    - Identify employees who worked more than 40 hours
    - Determine which project received the most working hours
    - Handle and report malformed lines
    - Display results in a formatted table

EXAMPLES:
    $0 data/timesheet_sample.csv
    $0 /path/to/timesheet.csv

EXIT CODES:
    0 - Success
    1 - Error (missing file, invalid data, etc.)

EOF
}

# Check for help flag
if [ "$INPUT_FILE" = "-h" ] || [ "$INPUT_FILE" = "--help" ]; then
    show_usage
    exit 0
fi

# Validate input arguments
if [ -z "$INPUT_FILE" ]; then
    print_error "No input file specified"
    echo "Usage: $0 <timesheet.csv>"
    echo "For more information, use: $0 --help"
    exit 1
fi

# Check if file exists
if [ ! -f "$INPUT_FILE" ]; then
    print_error "File '$INPUT_FILE' does not exist"
    exit 1
fi

# Check if file is readable
if [ ! -r "$INPUT_FILE" ]; then
    print_error "File '$INPUT_FILE' is not readable"
    exit 1
fi

# Check if file is empty
if [ ! -s "$INPUT_FILE" ]; then
    print_error "File '$INPUT_FILE' is empty"
    exit 1
fi

print_info "Processing timesheet file: $INPUT_FILE"
echo ""

# Read and validate header
header=$(head -n 1 "$INPUT_FILE")
expected_header="EmployeeID,Date,HoursWorked,ProjectName"

if [ "$header" != "$expected_header" ]; then
    print_error "Invalid CSV header"
    echo "Expected: $expected_header"
    echo "Found:    $header"
    exit 1
fi

print_success "CSV header validation passed"
echo ""

# Initialize associative arrays for tracking
declare -A employee_hours
declare -A project_hours
malformed_count=0
valid_lines=0

# Process CSV file (skip header)
line_number=1
while IFS= read -r line || [ -n "$line" ]; do
    line_number=$((line_number + 1))
    
    # Skip empty lines
    if [ -z "$line" ]; then
        continue
    fi
    
    # Parse CSV line
    IFS=',' read -r emp_id date hours project <<< "$line"
    
    # Validate that all fields are present
    if [ -z "$emp_id" ] || [ -z "$date" ] || [ -z "$hours" ] || [ -z "$project" ]; then
        print_warning "Malformed line $line_number: Missing fields"
        malformed_count=$((malformed_count + 1))
        continue
    fi
    
    # Validate hours is a number
    if ! [[ "$hours" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        print_warning "Malformed line $line_number: Invalid hours value '$hours'"
        malformed_count=$((malformed_count + 1))
        continue
    fi
    
    # Add to employee hours (using integer arithmetic for simplicity)
    hours_int=${hours%.*}  # Remove decimal part if present
    if [ -z "${employee_hours[$emp_id]}" ]; then
        employee_hours[$emp_id]=0
    fi
    employee_hours[$emp_id]=$((employee_hours[$emp_id] + hours_int))
    
    # Add to project hours
    if [ -z "${project_hours[$project]}" ]; then
        project_hours[$project]=0
    fi
    project_hours[$project]=$((project_hours[$project] + hours_int))
    
    valid_lines=$((valid_lines + 1))
done < <(tail -n +2 "$INPUT_FILE")

# Report malformed lines
if [ $malformed_count -gt 0 ]; then
    print_warning "Encountered $malformed_count malformed line(s)"
else
    print_success "No malformed lines found"
fi

echo ""
print_info "Processed $valid_lines valid timesheet entries"
echo ""

# Check if we have any valid data
if [ $valid_lines -eq 0 ]; then
    print_error "No valid data to process"
    exit 1
fi

# Generate report
echo "=========================================="
echo "       TIMESHEET SUMMARY REPORT          "
echo "=========================================="
echo ""

# Section 1: Total Hours per Employee
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TOTAL HOURS WORKED PER EMPLOYEE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-15s | %s\n" "Employee ID" "Total Hours"
echo "────────────────────────────────────────"

for emp_id in $(echo "${!employee_hours[@]}" | tr ' ' '\n' | sort); do
    printf "%-15s | %10d\n" "$emp_id" "${employee_hours[$emp_id]}"
done

echo ""

# Section 2: Employees working more than 40 hours
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  EMPLOYEES WORKING OVER 40 HOURS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

overtime_employees=()
for emp_id in "${!employee_hours[@]}"; do
    if [ "${employee_hours[$emp_id]}" -gt 40 ]; then
        overtime_employees+=("$emp_id")
    fi
done

if [ ${#overtime_employees[@]} -eq 0 ]; then
    echo "No employees worked more than 40 hours"
else
    printf "%-15s | %s\n" "Employee ID" "Total Hours"
    echo "────────────────────────────────────────"
    for emp_id in $(echo "${overtime_employees[@]}" | tr ' ' '\n' | sort); do
        printf "%-15s | %10d\n" "$emp_id" "${employee_hours[$emp_id]}"
    done
fi

echo ""

# Section 3: Project with most hours
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PROJECT WITH MOST WORKING HOURS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

max_hours=0
max_project=""

for project in "${!project_hours[@]}"; do
    if [ "${project_hours[$project]}" -gt "$max_hours" ]; then
        max_hours="${project_hours[$project]}"
        max_project="$project"
    fi
done

printf "%-25s | %s\n" "Project Name" "Total Hours"
echo "──────────────────────────────────────────"
printf "%-25s | %10d\n" "$max_project" "$max_hours"

echo ""

# Section 4: All Projects Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  HOURS PER PROJECT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-25s | %s\n" "Project Name" "Total Hours"
echo "──────────────────────────────────────────"

for project in $(echo "${!project_hours[@]}" | tr ' ' '\n' | sort); do
    printf "%-25s | %10d\n" "$project" "${project_hours[$project]}"
done

echo ""
echo "=========================================="
echo ""

print_success "Report generation completed successfully"
exit 0

