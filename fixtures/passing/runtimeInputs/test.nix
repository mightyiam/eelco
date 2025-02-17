{
  pkgs,
  eelco,
  ...
}:
eelco {
  inherit pkgs;
  src = ./.;
  runtimeInputs = [pkgs.python3];
}
