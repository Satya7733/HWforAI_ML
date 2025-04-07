import re
from collections import defaultdict

# Updated regex pattern to capture opcodes:
# Optionally matches a leading number and whitespace, then captures the opcode (assumed to be uppercase letters, digits, and underscores).
pattern = re.compile(r"^(?:\d+\s+)?([A-Z][A-Z0-9_]+)")

# Dictionary to count each opcode occurrence.
opcode_counts = defaultdict(int)

# Path to the file containing the bytecode.
file_path = 'MatrixMul_bytecode.txt'  # Update this path if needed #####################################################################

# Reading from the bytecode file.
try:
    with open(file_path, 'r') as file:
        for line in file:
            line = line.strip()
            if not line:
                continue  # Skip empty lines
            # Skip lines that are labels (e.g., "L1:" or "L11:")
            if re.match(r"^\s*L\d+:?", line):
                continue
            match = pattern.match(line)
            if match:
                opcode = match.group(1)
                opcode_counts[opcode] += 1
except FileNotFoundError:
    print(f"Error: The file '{file_path}' does not exist. Please check the path and try again.")
    exit(1)

# Calculate the total number of instructions.
total_instructions = sum(opcode_counts.values())

# Prepare the analysis report as a list of strings.
report_lines = []
report_lines.append("Bytecode Analysis Report")
report_lines.append("------------------------\n")
report_lines.append(f"Total Instructions: {total_instructions}\n")

# Produce individual instruction report in decreasing order.
report_lines.append("Individual Instruction Counts (Decreasing Order):")
sorted_opcodes = sorted(opcode_counts.items(), key=lambda item: item[1], reverse=True)
for opcode, count in sorted_opcodes:
    percent = (count / total_instructions * 100) if total_instructions > 0 else 0
    report_lines.append(f"{opcode}: {count} instructions ({percent:.2f}%)")

# Define function to consolidate opcodes into categories.
def get_category(opcode):
    if opcode.startswith("BINARY_") or opcode.startswith("INPLACE_"):
        return "Arithmetic"
    elif opcode.startswith("LOAD_"):
        return "Load"
    elif opcode.startswith("STORE_"):
        return "Store"
    elif opcode.startswith("RETURN_"):
        return "Return"
    else:
        return "Other"

# Consolidate opcode counts into categories.
category_counts = defaultdict(int)
for opcode, count in opcode_counts.items():
    category = get_category(opcode)
    category_counts[category] += count

# Report consolidated categories.
report_lines.append("\nConsolidated Categories:")
for cat in ["Arithmetic", "Load", "Store", "Return", "Other"]:
    count = category_counts[cat]
    percent = (count / total_instructions * 100) if total_instructions > 0 else 0
    report_lines.append(f"{cat}: {count} instructions ({percent:.2f}%)")

# Path for the output report file.
output_file_path = 'MatrixMul_analysis.txt' #######################################################

# Write the report to the specified output file.
with open(output_file_path, 'w') as output_file:
    output_file.write("\n".join(report_lines))

print(f"Analysis complete. Report saved to '{output_file_path}'.")
