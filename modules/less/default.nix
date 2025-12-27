{ adios }:
let
  inherit (adios) types;
in {
  name = "less";

  inputs = {
    nixpkgs.path = "/nixpkgs";
  };

  options = {
    flags = {
      type = types.string;
      # We're providing a default value here, that we actually override when
      # calling the impl - it's just here for demo purposes
      default = "-F";
    };
  };

  impl =
    { options, inputs }:
    let
      inherit (inputs.nixpkgs) pkgs;
      inherit (pkgs) symlinkJoin makeWrapper;
    in
    symlinkJoin {
      name = "less-wrapped";
      paths = [ pkgs.less ];
      buildInputs = [ makeWrapper ];
      postBuild = /* bash */ ''
        wrapProgram $out/bin/less \
          --set LESS "${options.flags}"
      '';
      meta.mainProgram = "less";
    };
}
