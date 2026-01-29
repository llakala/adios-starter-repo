{ pkgs, adios }:
let
  # We create a "root module", that then sets under modules as accessible from
  # it. Think of the `modules` field as allowing us to reach some module, so we
  # can then call it in a file like this. it's also used for inputs resolution
  # (long story, see the less module for a full explainer of this)
  root = {
    name = "root";

    # This is a helper function, that means we don't have to write out the files
    # to be called. However, for posterity, it would expand here to:
    #
    # modules = {
    #   nixpkgs = import ./nixpkgs.nix { inherit adios; };
    #   less = import ./less.nix { inherit adios; };
    # };
    modules = adios.lib.importModules ./modules;
  };

  # This is kinda crazy.
  # We have a bunch of modules. But our modules want to be able to read from
  # pkgs.
  #
  # We could inject pkgs when actually calling the modules, so the `modules`
  # attributes would instead look like:
  #
  # modules = {
  #   less = import ./less.nix { inherit adios pkgs; };
  # };
  #
  # But what if a module didn't use pkgs? This certainly isn't very lazy.
  #
  # Our solution is to create a `nixpkgs` module with a pkgs option. If a module
  # wants to read from `pkgs`, it just makes the nixpkgs module one of its
  # inputs, and reads from the value of `inputs.nixpkgs.pkgs`. Adios modules are
  # allowed to read from the options of another module, as long as you declare
  # your input relations (this is UNLIKE nixos modules).
  #
  # But how do we actually set the state of the `pkgs` option, so the other
  # modules can read from it? We need to change the state of the module, so when
  # a module tries to read from it, it gets our modified value.
  #
  # This is what we do here, in what's called "the eval stage". We inject a
  # value for the pkgs option, so when the other modules read from the nixpkgs
  # module, they'll get our custom value!
  tree = adios root {
    options = {
      "/nixpkgs" = {
        inherit pkgs;
      };
    };
  };
in
  # This gives us access to all the module we created. If you inspected the
  # modules in the repl, you'd find they were still attribute sets, just like
  # when we wrote them. However, they got some extra attributes added to them in
  # the eval stage - a functor, so that we can _call_ a module. If you imported
  # this file under `wrappers`, you could do `wrappers.foo {}`, which would call
  # the impl of this module with all the default values for the options.
  #
  # We can't just call the impl directly - the impl takes values for options and
  # inputs, that we don't know. the options might be resolved from default
  # values, and if we wanted to pass the inputs, we'd have to manually link them
  # - something we'd like to avoid. The eval stage creates a functor that does
  # this annoying work for us.
  #
  # If we wanted to override the state of an option, we'd do:
  # `wrappers.foo { someOption = 5; }`
  tree.modules
