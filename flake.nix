{
  description =
    "A minimal & fast plugin loader for nixified neovim configurations";

  inputs.utils.url = "github:NewDawn0/nixUtils";

  outputs = { self, utils }: {
    overlays.default = final: prev: {
      vimPlugins = prev.vimPlugins // {
        loader-nvim = self.packages.${prev.system}.default;
      };
    };
    packages = utils.lib.eachSystem { } (pkgs: {
      default = pkgs.vimUtils.buildVimPlugin {
        name = "loader-nvim";
        src = ./.;
        meta = {
          description =
            "A minimal & fast plugin loader for nixified neovim configurations";
          homepage = "https://github.com/NewDawn0/loader.nvim";
          license = pkgs.lib.licenses.mit;
          maintainers = with pkgs.lib.maintainers; [ NewDawn0 ];
        };
      };
    });
  };
}
