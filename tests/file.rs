mod util;

use assert_fs::fixture::FileWriteStr;

use indoc::indoc;
use util::with_eelco;

#[test]
fn file_creation() {
    with_eelco(|file, eelco| {
        file.write_str(indoc! {
        "
                
        "})
            .unwrap();
    })
}
