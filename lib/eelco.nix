{
  pkgs,
  src,
  # TODO: discuss if we should extract all this into a generic `derivationArgs` (or perhaps `mkDerivationArgs`?)
  runtimeInputs ? [],
  env ? {},
  requiredSystemFeatures ? [],
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
  in
    {
      "file-upsert" = ''
        mkdir --parents "${builtins.dirOf step.path}"
        cp ${file} ${lib.escapeShellArg step.path}
      '';
      "bash-session" = ''
        ${lib.getExe teshIt} < ${file}
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
          cp -r ${prevDrv}/ $out
          chmod +w --recursive $out
          cd $out

          ${stepToCommand {inherit step exampleId;}}
        ''
    )
    (pkgs.runCommandNoCC "empty" {} "mkdir $out")
    example.steps;
in
  lib.pipe src [
    (lib.fileset.fileFilter (file: file.hasExt "md"))
    lib.fileset.toList
    (map toString)
    (map builtins.unsafeDiscardStringContext)
    (map (path: let
      relativePath = lib.pipe path [
        (s: /. + s)
        lib.path.splitRoot
        (lib.getAttr "subpath")
        lib.path.subpath.components
        (lib.lists.drop 3)
        lib.path.subpath.join
      ];
    in
      lib.nameValuePair relativePath (builtins.readFile path)))
    lib.listToAttrs
    (lib.mapAttrs (import ./parse.nix lib))
    (
      examplesErrorsByPath: {
        examplesByPath =
          lib.mapAttrs (path: {examples, ...}:
            examples);
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
