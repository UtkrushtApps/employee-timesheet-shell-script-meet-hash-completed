# Task Overview

Managing employee work hours and project allocation is a common task for DevOps and backend teams dealing with exported CSV timesheet data. Manual processing can introduce errors and delays, especially as data volumes grow. You are tasked with automating the generation of a summary report from CSV-formatted employee timesheet exports, making it easier to track workload distribution and spot potential overwork or resource bottlenecks. This script will streamline how teams interpret work logs and project efforts.

---

## Objectives

- Implement a shell script that validates the input CSV and only processes files with the correct structure
- Automate calculation of total hours worked per employee from the CSV for a single week
- Identify employees who have logged more than 40 hours in that week and include their IDs in the report
- Determine which project received the most working hours during the week
- Handle malformed lines by skipping them and reporting the number encountered
- Generate an output summary table that is clearly formatted and understandable
- Ensure the script can be safely run with different data files and edge cases (empty file, bad input, etc.)
- Display clear feedback and error reporting throughout script execution

---

## How to Verify

- Run the script with the provided sample CSV; verify totals per employee are correct
- Check employees flagged as working over 40 hours match the calculated totals
- Confirm the most worked-on project is accurately identified
- Verify that malformed or missing fields in input data are gracefully reported and not included in the summary
- Test the script with a CSV missing the required header and confirm it stops with a meaningful error
- Execute the script with empty or non-existent files and verify it handles these cases without crashing
- Confirm all output tables are well-aligned and easy to interpret
- Validate which exit codes are returned for successful and unsuccessful scenarios

---

## Helpful Tips

- Consider how to validate the CSV header before processing; what if it's missing or different?
- Think about how to skip or flag malformed or incomplete data rows without breaking the script
- Explore splitting fields using safe techniques for handling CSVs that might include extra commas or spaces
- Review how to accumulate values (totals per employee or project) using arrays or temporary files as needed
- Look into ways to present data in an aligned, readable table rather than unstructured text
- Consider providing useful error messages when the script receives invalid input or missing files
- Remember to check exit status of key commands for error handling
- Consider script efficiency: can you avoid looping over the file multiple times unnecessarily?
- Think about how easy it is for someone else to read, test, and maintain your script
- Explore handling input file names with spaces or special characters safely
