# Every module is passed `adios` directly
adios:

{
  name = "nixpkgs";

  options = {
    pkgs = {
      # No default value - the value is injected in the eval stage
      type = adios.types.attrs;
    };
  };
}
