import subprocess
import sys

def is_valid(output: str) -> bool:
    cp = subprocess.run(["nix-store", "--verify-path", output], text=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return cp.returncode == 0

drv = sys.argv[1]

cp = subprocess.run(["nix-store", "--query", "--references", drv], text=True, capture_output=True, check=True)
references = cp.stdout.splitlines()

failed_references = []
for reference in references:
    cp = subprocess.run([
        "nix-store", 
        "--query",
        "--outputs",
        reference,
    ], text=True, capture_output=True, check=True)
    outputs = cp.stdout.splitlines()

    invalid_outputs = [
        output for output in outputs if not is_valid(output)
    ]
    if len(invalid_outputs) > 0:
        failed_references.append(reference)

for failed_reference in failed_references:
    subprocess.run(["nix-store", "--read-log", failed_reference], check=True)
