use crate::example_id::ExampleId;

#[derive(Debug, Clone)]
pub(crate) struct FileExampleState {
    pub(crate) example: FileExample,
}

#[]
pub(crate) struct FileExample {
    pub(crate) id: ExampleId,
}
impl FileExampleState {
    pub(crate) fn new(file_example: FileExample) -> Self {
        Self {
            FileExample: file_example,
        }
    }
}
