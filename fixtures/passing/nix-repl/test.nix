{
  self,
  pkgs,
  eelco,
  ...
}:
eelco {
  inherit pkgs;
  src = ./.;
  runtimeInputs = [pkgs.nixVersions.latest];
  requiredSystemFeatures = ["recursive-nix"];
  env.NIX_PATH = "nixpkgs=${self.inputs.nixpkgs}";
  prompts = [
    "nix-repl> "
  ];
}
