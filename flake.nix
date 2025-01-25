{
  description =
    "A minimal & fast plugin loader for nixified neovim configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    utils.url = "github:NewDawn0/nixUtils";
  };

  outputs = { self, nixpkgs, utils }: {
    overlays.default = final: prev: {
      loader-nvim = self.packages.${prev.system}.default;
    };
    packages = utils.lib.eachSystem { inherit nixpkgs; } (pkgs: {
      default = pkgs.vimUtils.buildVimPlugin {
        name = "loader-nvim";
        src = ./.;
      };
    });
  };
}
