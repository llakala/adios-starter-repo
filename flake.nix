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
      # This lets us parameterize over system - see
      # https://ayats.org/blog/no-flake-utils
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
      wrapperModules = forAllSystems (pkgs: _:
        import ./default.nix {
          inherit pkgs;
          adios = inputs.adios.adios;
        }
      );

      # Of course, the packages we expose. This lets us actually build our
      # wrappers, with `nix build .#less`. Then we can inspect their contents by
      # looking through the `result` symlink and making sure they got
      # constructed as we expected.
      #
      # You'll notice I didn't say to use `nix run`. This is because for
      # actually executing your wrapped programs, I instead recommend using a
      # direnv-powered devshell (as is defined below).
      packages = forAllSystems (
        pkgs: system:
        let
          # `self` is a special flake input that's always included, and lets us
          # read from another one of our flake outputs easily.
          wrappers = inputs.self.wrapperModules.${system};
        in {
          # Call the less module with our desired options. We could just pass
          # `{}` to use all the defaults, but we're gonna override a value here
          # for demo purposes
          less = wrappers.less {
            flags = "-F -i";
          };
        }
      );

      # Devshell set up with direnv (envrc defined in-repo), so that any changes
      # to our wrappers result in instant application
      #
      # Rather than just installing our wrappers to our nixos/hm config, and
      # rebuilding whenever we want to see a change, we prefer to iterate in a
      # devshell. Obviously the nature of a devshell means that it won't apply
      # in other directories - so the idea is to iterate on changes while in
      # this repo, then rebuild when we're done to propagate the changes to
      # every dir.
      devShells = forAllSystems (
        pkgs: system:
        let
          # We don't read from the wrapperModules output, since that's just for
          # debugging, and they aren't instantiated with our options there. The
          # packages output is where they actually get turned into derivations.
          #
          # The three stages might seem unnecessary - but exposing
          # wrapperModules is useful for debugging, and exposing `packages` lets
          # us not just load wrappers in the devshell, but also within something
          # like our nixos/home-manager config
          wrappers = inputs.self.packages.${system};
        in {
          default = pkgs.mkShellNoCC {
            packages = [
              wrappers.less
            ];
          };
        }
      );
    };
}
