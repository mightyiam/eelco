mod util;

use assert_fs::fixture::FileWriteStr;

use indoc::indoc;
use util::with_eelco;

#[test]
fn file_creation() {
    with_eelco(|file, eelco| {
        file.write_str(indoc! {"
            ```file default.nix
            
            ```
        "})
            .unwrap();

        let file_path = file.path().to_str().unwrap();
    })
}
