{
  self,
  pkgs,
}: let
  inherit (pkgs) lib;

  passingFixturesPath = ./fixtures/passing;

  passingTests = lib.pipe passingFixturesPath [
    builtins.readDir
    (lib.mapAttrs (
      path: _type:
        import "${passingFixturesPath}/${path}/test.nix" {
          inherit pkgs lib;
          inherit (self.lib) eelco;
        }
    ))
  ];

  failing = {
    bad-bash-session =
      pkgs.runCommandNoCC "eelco-bad-bash-session" {
        nativeBuildInputs = [pkgs.nixVersions.latest pkgs.python3];
        requiredSystemFeatures = ["recursive-nix"];
        NIX_PATH = "nixpkgs=${self.inputs.nixpkgs}:eelco=${self}";
      } ''
        drv=$(nix-instantiate ${./fixtures/failing/bad-bash-session}/test.nix)

        if ! nix-build $drv; then
          echo "Failed successfully"
        else
          echo "Expected to fail but succeeded"
          exit 1
        fi

        python ${./print-log-of-failed-drv-references.py} $drv > failed.log

        echo "**** start catting"
        cat failed.log
        echo "**** end catting"
        if ! grep "Goodbye" $log_file; then
          echo "Test should have printed a failure message"
          exit 1
        fi

        touch $out
      '';

    unmarked-fenced-code-block =
      pkgs.runCommandNoCC "eelco-unmarked-fenced-code-block" {
        nativeBuildInputs = [pkgs.nixVersions.latest pkgs.python3];
        requiredSystemFeatures = ["recursive-nix"];
        NIX_PATH = "nixpkgs=${self.inputs.nixpkgs}:eelco=${self}";
      } ''
        drv=$(nix-instantiate ${./fixtures/failing/unmarked-fenced-code-block}/test.nix)

        if ! nix-build $drv; then
          echo "Failed successfully"
        else
          echo "Expected to fail but succeeded"
          exit 1
        fi

        python ${./print-log-of-failed-drv-references.py} $drv > failed.log

        # <<< TODO: this is bogus >>>
        echo "**** start catting"
        cat failed.log
        echo "**** end catting"
        if ! grep "Goodbye" $log_file; then
          echo "Test should have printed a failure message"
          exit 1
        fi

        touch $out
      '';
  };
in
  passingTests
  // {
    # We haven't been able to get these tests to work, because recursive-nix
    # doesn't give you access to the logs of failing builds.
    # A couple ideas of things to try next:
    #  - Add `/nix/var/log` to extra-sandbox-paths.
    #  - Write a nixosTest which uses nix internally.
    # bad-bash-session = failing.failing.bad-bash-session;
    # unmarked-fenced-code-block = failing.unmarked-fenced-code-block;
  }
