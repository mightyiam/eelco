#[derive(Debug, Default)]
pub(crate) enum FileExampleState {
  #[default]
  Created,
  Parsed,
}