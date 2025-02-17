from tesh.extract import ShellSession
from tesh.extract import extract_blocks
from tesh.test import test
import sys
import hashlib

def test_it(session_text: str):
    debug = False

    session = ShellSession(
        lines=session_text.splitlines(),
        blocks=[], # This is populated later by `extract_blocks`.
        id_=hashlib.sha256(session_text.encode()).hexdigest(),
    )
    extract_blocks(session, verbose=debug)

    test(filename="bogus", session=session, verbose=debug, debug=debug)

def main():
    test_it(sys.stdin.read())

if __name__ == "__main__":
    main()
