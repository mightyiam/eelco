{
  pkgs,
  eelco,
  ...
}:
eelco {
  inherit pkgs;
  src = ./.;
}
