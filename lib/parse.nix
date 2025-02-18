lib: path: content: let
  parseOpeningFence = line: let
    openingFenceMatch = lib.match "^(```+)(.*)$" line;
  in
    if openingFenceMatch == null
    then null
    else let
      infoAttrs = lib.pipe openingFenceMatch [
        lib.last
        (lib.splitString " ")
        (map (word: let
          keyAndMaybeValue = lib.splitString "=" word;
        in
          lib.nameValuePair (lib.head keyAndMaybeValue) (
            if lib.length keyAndMaybeValue == 1
            then null
            else lib.last keyAndMaybeValue
          )))
        lib.listToAttrs
      ];
      fenceDepth = lib.stringLength (lib.elemAt openingFenceMatch 0);
    in
      if infoAttrs ? example
      then {
        inherit fenceDepth;
        type = "example";
        exampleName = infoAttrs.example;
      }
      else
        (
          if infoAttrs ? not-tested
          then {
            inherit fenceDepth;
            type = "not-tested";
          }
          else {
            inherit fenceDepth;
            type = "error";
            error = "Code fence needs to have `example=<name>` or `not-tested`";
          }
        );

  isClosingFence = line: fenceDepth: line == lib.strings.replicate fenceDepth "`";

  foldLine = (
    {
      state,
      examples,
      errors,
      ...
    } @ acc: {
      index,
      line,
    }:
      acc
      // {
        prevLineIndex = index;
      }
      // ({
          "in-root" = let
            filePathMatch = lib.match "^`([^`]+)`:$" line;
          in
            if filePathMatch != null
            then {
              state = {
                type = "in-file-op-step";
                exampleFilePath = lib.elemAt filePathMatch 0;
              };
            }
            else let
              maybeOpeningFence = parseOpeningFence line;
            in (
              if maybeOpeningFence != null
              then let
                openingFence = maybeOpeningFence;
              in
                {
                  example = let
                    example =
                      examples.${openingFence.exampleName}
                      or {
                        steps = [];
                      };
                  in {
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
                  };
                  not-tested = {
                    state = {
                      type = "in-fenced-code-block";
                      inherit openingFence;
                    };
                  };
                  error = {
                    state = {
                      type = "in-fenced-code-block";
                      inherit openingFence;
                    };
                    errors =
                      errors
                      ++ [
                        {
                          inherit path;
                          lineIndex = index;
                          message = openingFence.error;
                        }
                      ];
                  };
                }
                .${openingFence.type}
              else {}
            );
          "in-fenced-code-block" = let
          in
            if isClosingFence line state.openingFence.fenceDepth
            then {
              state.type = "in-root";
            }
            else {};
          "in-step-fenced-code-block" = let
            exampleName = state.openingFence.exampleName;
            example = examples.${exampleName} or (throw "In state in-step-fenced-code-block, but couldn't find an example named ${state.openingFence.exampleName}");
            prevSteps = lib.lists.init example.steps;
            step = lib.lists.last example.steps;
          in
            if isClosingFence line state.openingFence.fenceDepth
            then {
              state.type = "in-root";
            }
            else {
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
            then {}
            else let
              maybeOpeningFence = parseOpeningFence line;
            in
              if maybeOpeningFence != null
              then let
                openingFence = maybeOpeningFence;
                example =
                  examples.${openingFence.exampleName}
                  or {steps = [];};
              in (
                if openingFence ? error
                then {
                  state = {
                    type = "in-fenced-code-block";
                    inherit openingFence;
                  };
                  errors =
                    errors
                    ++ [
                      {
                        inherit path;
                        lineIndex = index;
                        message = openingFence.error;
                      }
                    ];
                }
                else {
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
                                path = state.exampleFilePath;
                                index = builtins.length example.steps;
                                type = "file-upsert";
                                text = null;
                              }
                            ];
                        };
                    };
                }
              )
              else {
                state.type = "in-root";
                errors =
                  errors
                  ++ [
                    {
                      inherit path;
                      lineIndex = index;
                      message = "Invalid line after path statement";
                    }
                  ];
              };
        }
        .${state.type})
  );
in
  lib.pipe content [
    (lib.splitString "\n")
    (lib.imap (index: line: {inherit index line;}))
    (lib.foldl foldLine
      {
        state = {
          type = "in-root";
        };
        prevLineIndex = 0;
        examples = {};
        errors = [];
      })
    (result:
      if result.state.type != "in-root"
      then
        result
        // {
          errors =
            result.errors
            ++ [
              {
                inherit path;
                lineIndex = result.prevLineIndex;
                error = "finished parsing but state = `${result.state.type}`";
              }
            ];
        }
      else result)
    (lib.getAttrs ["examples" "errors"])
  ]
