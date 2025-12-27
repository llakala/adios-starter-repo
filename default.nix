{ pkgs, adios }:
let
  root = {
    name = "root";
    # This is a helper function that means we don't have to write out the files to be called
    # However, for posterity, it would expand here to:
    # modules = {
    #   nixpkgs = import ./nixpkgs.nix { inherit adios; };
    #   less = import ./less/default.nix { inherit adios; };
    # };
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
