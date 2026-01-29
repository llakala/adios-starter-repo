# Every module is passed `adios` directly. Most of the time, we only want to get
# the `types` attribute from the adios attrset, so we can use a set pattern to
# only grab types.
{ types, ... }:

{
  # The name parameter used to have a special adios meaning, but it's now only
  # really useful for improving error logs. Feel free to omit it if you want - I
  # just include it by habit.
  name = "less";

  # Special toplevel attribute of adios modules. Here, we list modules that we'd
  # like read access to. You know how in nixos, you can do
  # `config.programs.git.enable` to read from the git module? Well, this is
  # pretty much the same thing - but because adios is lazy, we have to specify
  # which modules we want to read from. We can read from another module's
  # options, or (in one of my unmerged PRs), even call that module's impl.
  inputs = {
    # This path syntax is weird. It is _not_ a path on disk. Instead, it's a
    # path "from the root module", following the `modules` tree.
    #
    # Remember how the root module (defined in the default.nix) had a modules
    # attribute that resolved to this?
    #
    # modules = {
    #   nixpkgs = import ./nixpkgs.nix { inherit adios; };
    #   less = import ./less.nix { inherit adios; };
    # };
    #
    # Well, this "path" uses the attribute names seen here. If we had instead
    # changed the modules attributes to look like this:
    #
    # modules = {
    #   OTHER_NAME = import ./nixpkgs.nix { inherit adios; };
    #   less = import ./less.nix { inherit adios; };
    # };
    #
    # Then to use the nixpkgs module as an input, we'd have to do `/OTHER_NAME`

    # This also works in a nested context. Let's imagine a world where the
    # nixpkgs module also had its own `modules` attrset, that looked like this:
    #
    # # nixpkgs.nix
    # modules = {
    #   example = import ./example.nix { inherit adios; };
    # };
    #
    # Then to access the example module as an input, we'd do `/nixpkgs/example`
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

  # An adios module is essentially a fancy function. We create some options,
  # define some inputs to read from, and then call the `impl` of the module with
  # the values of those options and inputs.
  #
  # A module's impl "produces" what we wanted from the module. In the case of
  # this module, it creates the less derivation. Note that this impl is NOT
  # changing the value of any options. It's just producing a result, that we're
  # free to use or ignore.
  #
  # This is a big part of why adios is able to be lazy. You can have 1000
  # modules that all create wrappers for individual programs, but if you never
  # call the impl of those modules, then their wrappers can be completely
  # ignored.
  #
  # Finally, note that if you want a module to not just create some output, but
  # also mutate the options of other modules, there IS actually a way to do
  # this, from one of my PRs. It's very new, and not user-friendly at all yet -
  # so I recommend ignoring it for now. However, if you want to take a plunge
  # into unfriendly territory, check out https://github.com/adisbladis/adios/pull/26.
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
      # meta.mainProgram sets the executable within `/bin` to be used when
      # executing `nix run`. If there are multiple executables in /bin, the nix
      # cli isn't sure which to choose, and gives a warning. Specifying the
      # path to the binary fixes this! In context, we're saying that the binary
      # to be run is located at `/bin/less` within the built derivation.
      meta.mainProgram = "less";
    };
}
