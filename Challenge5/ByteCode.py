import dis
import io

# Read the Python source code
with open("AES.py", "r") as file:
    source_code = file.read()

# Compile the code into bytecode
compiled_code = compile(source_code, "AES.py", "exec")

# Capture the disassembly output
output = io.StringIO()
dis.dis(compiled_code, file=output)
bytecode_text = output.getvalue()  # Get the output as a string

# Save the bytecode to a text file
with open("AES_bytecode.txt", "w") as output_file:
    output_file.write(bytecode_text)

print("Bytecode saved to bytecode.txt")
