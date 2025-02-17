lib: path: content: let
  parseOpeningFence = {
    line,
    index,
  }: let
    # <<< openingFenceMatch = lib.match "^(```+).* example=([^ ]+)( |$)" line;
    openingFenceMatch = lib.match "^(```+)(.*)$" line;
  in
    if openingFenceMatch == null
    then null
    else let
      infoString = lib.elemAt openingFenceMatch 1;
      # <<< exampleMatch = lib.match "example=([^ ]+)" line;
      infoWords = lib.strings.splitString " " infoString;
    in {
      fenceDepth = lib.stringLength (lib.elemAt openingFenceMatch 0);
      exampleName = lib.elemAt openingFenceMatch 1;
    };

  isClosingFence = line: fenceDepth: line == lib.strings.replicate fenceDepth "`";

  foldLine = (
    {
      state,
      examples,
    }: {
      index,
      line,
    }:
      {
        "in-root" = let
          filePathMatch = lib.match "^`([^`]+)`:$" line;
        in
          if filePathMatch != null
          then {
            state = {
              type = "in-file-op-step";
              filePath = lib.elemAt filePathMatch 0;
            };
            inherit examples;
          }
          else let
            openingFence = parseOpeningFence {inherit index line;};
            example =
              examples.${openingFence.exampleName}
              or {
                steps = [];
              };
          in (
            if openingFence != null
            then {
              state = {
                type = "in-step-fenced-code-block";
                inherit openingFence;
              };
              examples =
                examples
                // {
                  ${openingFence.exampleName} =
                    example
                    // {
                      steps =
                        example.steps
                        ++ [
                          {
                            index = builtins.length example.steps;
                            type = "bash-session";
                            text = null;
                          }
                        ];
                    };
                };
            }
            else {inherit state examples;}
          );
        "in-step-fenced-code-block" = let
          exampleName = state.openingFence.exampleName;
          example = examples.${exampleName} or (throw "In state in-step-fenced-code-block, but couldn't find an example named ${state.openingFence.exampleName}");
          prevSteps = lib.lists.init example.steps;
          step = lib.lists.last example.steps;
        in
          if isClosingFence line state.openingFence.fenceDepth
          then {
            state.type = "in-root";
            inherit examples;
          }
          else {
            inherit state;
            examples =
              examples
              // {
                ${exampleName} =
                  example
                  // {
                    steps =
                      prevSteps
                      ++ [
                        (step
                          // {
                            text =
                              (
                                if step.text == null
                                then ""
                                else step.text + "\n"
                              )
                              + line;
                          })
                      ];
                  };
              };
          };
        "in-file-op-step" =
          if line == ""
          then {inherit state examples;}
          else let
            openingFence = parseOpeningFence line;
            example =
              examples.${openingFence.exampleName}
              or {steps = [];};
          in
            if openingFence != null
            then {
              state = {
                type = "in-step-fenced-code-block";
                inherit openingFence;
              };
              examples =
                examples
                // {
                  ${openingFence.exampleName} =
                    example
                    // {
                      steps =
                        example.steps
                        ++ [
                          {
                            path = state.filePath;
                            index = builtins.length example.steps;
                            type = "file-upsert";
                            text = null;
                          }
                        ];
                    };
                };
            }
            else throw "Invalid line after path statement ${path}:${toString index}: ${builtins.toJSON line}";
      }
      .${state.type}
  );
in
  lib.pipe content [
    (lib.splitString "\n")
    (lib.imap (index: line: {inherit index line;}))
    (lib.foldl foldLine
      {
        state.type = "in-root";
        examples = {};
      })
    (result: assert lib.assertMsg (result.state.type == "in-root") "finished parsing but state = `${result.state.type}`"; result)
    (lib.getAttr "examples")
  ]
