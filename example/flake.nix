{
  description = "NewDawn0's nixified nvim config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    utils = {
      url = "github:NewDawn0/nixUtils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    loader = {
      url = "github:NewDawn0/loader.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, utils, ... }@inputs:
    let
      mkPkgs = system:
        import nixpkgs {
          inherit system;
          overlays = [ inputs.loader.overlays.default ];
        };
    in {
      # utils.lib.eachSystem just loops over all the systems providing the correct packages
      # Here we use a custom mkPkgs function with an overlay which always exposing the loader.nvim plugin
      packages = utils.lib.eachSystem { inherit mkPkgs; } (pkgs:
        let nvim = import ./nvim.nix { inherit pkgs; };
        in { default = nvim; });
    };
}
