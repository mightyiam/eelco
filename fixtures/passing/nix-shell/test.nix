{
  pkgs,
  eelco,
  ...
}:
eelco {
  inherit pkgs;
  src = ./.;
  env.NIX_PATH = "nixpkgs=${pkgs.path}";
  runtimeInputs = [pkgs.nix];
  requiredSystemFeatures = ["recursive-nix"];
}
