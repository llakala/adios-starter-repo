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
      wrappers = forAllSystems (pkgs: _:
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
      # actually executing your wrapped programs, I instead recommend creating a
      # direnv-powered devshell. I hope to add an example of that to the repo in
      # the future.
      packages = forAllSystems (
        pkgs: system:
        let
          # `self` is a special flake input that's always included, and lets us
          # read from another one of our flake outputs easily.
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
