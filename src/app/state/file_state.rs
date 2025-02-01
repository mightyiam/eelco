use crate::example_id::ExampleId;

#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct FileExampleState {
    pub(crate) example: FileExample,
}

impl FileExampleState {
    pub(crate) fn new(file_example: &FileExample) -> Self {
        Self {
            example: file_example.clone(),
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub(crate) struct FileExample {
    pub(crate) id: ExampleId,
}

impl FileExample {
    pub(crate) fn new(id: ExampleId) -> Self {
        Self { id }
    }
}
