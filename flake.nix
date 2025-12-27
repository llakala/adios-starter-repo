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
        (system: apply inputs.nixpkgs.legacyPackages.${system});
    in {
      packages = forAllSystems (
        pkgs:
        let
          wrappers = import ./default.nix {
            inherit pkgs;
            adios = inputs.adios.adios;
          };
        in
        {
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
