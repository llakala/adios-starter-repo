{ pkgs, adios }:
let
  root = {
    name = "root";
    modules = adios.lib.importModules ./modules;
  };

  tree = (adios root).eval {
    options = {
      "/nixpkgs" = {
        inherit pkgs;
      };
    };
  };
in
  tree.root.modules
