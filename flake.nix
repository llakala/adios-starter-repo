{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # You could point this to one of my PRs if you wanted "new features" - but
    # i'll start you with vanilla
    adios.url = "github:adisbladis/adios";
  };

  outputs = inputs:
    let
      inherit (inputs.nixpkgs) lib;
      forAllSystems = apply:
        lib.genAttrs
        [ "x86_64-linux" ]
        (system: apply inputs.nixpkgs.legacyPackages.${system} system);
    in {
      # This is for checking out what modules look like in the repl
      # To do this, do:
      # > nix repl .
      # You can then read from `wrappers.$YOUR_SYSTEM` to see what they actually
      # end up being resolved to
      wrappers = forAllSystems (pkgs: _:
        import ./default.nix {
          inherit pkgs;
          adios = inputs.adios.adios;
        }
      );
      packages = forAllSystems (
        pkgs: system:
        let
          wrappers = inputs.self.wrappers.${system};
        in {
          # Call the less module with our desired options. We could just pass
          # `{}` to use all the defaults, but we're gonna override a value here
          # for demo purposes
          less = wrappers.less {
            flags = "-F -i";
          };
        }
      );
    };
}
