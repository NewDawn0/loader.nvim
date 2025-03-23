{
  description = "NewDawn0's nixified nvim config";

  inputs = {
    utils.url = "github:NewDawn0/nixUtils";
    loader-nvim = {
      url = "github:NewDawn0/loader.nvim";
      inputs.utils.follows = "utils";
    };
  };
  outputs = { utils, ... }@inputs: {
    # utils.lib.eachSystem just loops over all the systems providing the correct packages
    # Here we use a custom mkPkgs function with an overlay which always exposing the loader.nvim plugin
    packages = utils.lib.eachSystem {
      overlays = [ inputs.loader-nvim.overlays.default ];
    } (pkgs:
      let nvim = import ./nvim.nix { inherit pkgs; };
      in { default = nvim; });
  };
}
