from tesh.extract import ShellSession
from tesh.extract import extract_blocks
from tesh.test import test
import sys
import hashlib
import argparse

def test_it(session_text: str, prompts: list[str]):
    debug = False

    session = ShellSession(
        lines=session_text.splitlines(),
        blocks=[], # This is populated later by `extract_blocks`.
        id_=hashlib.sha256(session_text.encode()).hexdigest(),
        ps1=prompts,
        timeout=30,
    )
    extract_blocks(session, verbose=debug)

    test(filename="bogus", session=session, verbose=debug, debug=debug)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("prompt", nargs="*")
    args = parser.parse_args()
    test_it(sys.stdin.read(), args.prompt)

if __name__ == "__main__":
    main()
