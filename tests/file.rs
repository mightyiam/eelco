mod util;

use assert_fs::fixture::FileWriteStr;
use indoc::indoc;
use predicates::str::contains;
use util::with_eelco;

#[test]
fn fails_file_creation() {
    with_eelco(|file, eelco| {
        file.write_str(indoc! {"
            ```file flake.nix 
            
            ```
        "})
            .unwrap();

        eelco.assert().failure().stderr(contains("File name is "));
    })
}
