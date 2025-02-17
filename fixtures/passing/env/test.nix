{
  pkgs,
  eelco,
  ...
}:
eelco {
  inherit pkgs;
  src = ./.;
  env.AWESOME_ENV_VAR = "awesome";
}
