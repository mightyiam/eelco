{
  pkgs,
  src,
  # TODO: discuss if we should extract all this into a generic `derivationArgs` (or perhaps `mkDerivationArgs`?)
  runtimeInputs ? [],
  env ? {},
  requiredSystemFeatures ? [],
  prompts ? [],
  timeout ? 30,
}: let
  inherit (pkgs) lib;

  teshIt = let
    venv = pkgs.python3.withPackages (_: [
      (pkgs.tesh.overrideAttrs (oldAttrs: {
        patches =
          (oldAttrs.patches or [])
          ++ [
            (
              pkgs.fetchpatch {
                url = "https://github.com/OceanSprint/tesh/commit/3c8ae14ae10b93e54fee112f25cee9bd5937d73f.patch";
                hash = "sha256-T8EXir3507nJEHWyVq2ud+DjoiUxueY/QAfJnBGO4Yw=";
              }
            )
            ./repr.patch
          ];
      }))
    ]);
  in
    pkgs.writeShellScriptBin "eelco-tesh-it" ''
      exec ${lib.getExe venv} ${./tesh-it.py} "$@"
    '';

  stepToCommand = {
    step,
    exampleId,
  }: let
    file = pkgs.writeText "eelco-${exampleId}:${toString step.index}" step.text;
    teshArgs = lib.pipe prompts [
      (map (prompt: "--prompt ${lib.escapeShellArg prompt}"))
      (lib.concatStringsSep " ")
    ];
  in
    {
      "file-upsert" = ''
        mkdir --parents "${builtins.dirOf step.path}"
        cp ${file} ${lib.escapeShellArg step.path}
      '';
      "bash-session" = ''
        ${lib.getExe teshIt} ${teshArgs} --timeout ${toString timeout} < ${file}
      '';
    }
    .${step.type};

  mkExampleDerivation = exampleId: example:
    lib.foldl (
      prevDrv: step:
        pkgs.runCommandNoCC "eelco-${exampleId}:${toString step.index}" {
          nativeBuildInputs = runtimeInputs;
          inherit env requiredSystemFeatures;
        } ''
          cp -r ${prevDrv}/ ./tmp
          chmod +w --recursive ./tmp

          (
            cd ./tmp
            ${stepToCommand {inherit step exampleId;}}
          )

          mv ./tmp $out
        ''
    )
    (pkgs.runCommandNoCC "empty" {} "mkdir $out")
    example.steps;
in
  lib.pipe src [
    (lib.fileset.fileFilter (file: file.hasExt "md"))
    lib.fileset.toList
    (map (path: let
      relativePath = lib.path.removePrefix src path;
    in
      lib.nameValuePair relativePath (builtins.readFile path)))
    lib.listToAttrs
    (lib.mapAttrs (import ./parse.nix lib))
    (
      examplesErrorsByPath: {
        examplesByPath = lib.mapAttrs (path: {examples, ...}:
          examples)
        examplesErrorsByPath;
        errors = lib.pipe examplesErrorsByPath [
          (lib.mapAttrsToList (path: {errors, ...}: errors))
          lib.flatten
        ];
      }
    )
    ({
      examplesByPath,
      errors,
    }: let
      errorMsg = lib.concatStringsSep "\n" (map ({
        path,
        lineIndex,
        message,
      }: "- ${path}:${toString lineIndex} ${message}")
      errors);
    in
      assert lib.assertMsg (errors == []) "finished parsing, with ${toString (builtins.length errors)} error(s)\n${errorMsg}"; examplesByPath)
    (lib.concatMapAttrs (
      path: examples:
        lib.mapAttrs' (exampleName: steps: lib.nameValuePair "${path}:${exampleName}" steps) examples
    ))
    (lib.mapAttrsToList mkExampleDerivation)
    (drvs:
      # TODO: include a list of all examples in the resulting derivation
        pkgs.symlinkJoin {
          name = "eelco-examples";
          paths = drvs;
        })
  ]
