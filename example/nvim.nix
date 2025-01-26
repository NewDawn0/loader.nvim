{ pkgs }:
let
  runtime = import ./runtime.nix { inherit pkgs; };
  plugins = import ./plugins.nix { inherit pkgs; };
  ndnvimRtp = pkgs.stdenv.mkDerivation {
    name = "ndnvimRtp";
    src = ./nvim;
    installPhase = ''
      mkdir -p $out/lua
      cp -r lua $out/lua
      rm -r init.lua lua
    '';
  };
  nvim = pkgs.neovim.override {
    configure = {
      # Loader loaded immediately
      packages.all.start = with pkgs.vimPlugins; [ loader-nvim ];
      # Plugins loaded by loader
      packages.all.opt = plugins;
      customRC = ''
        lua <<EOF
        -- Startup optimisations
        vim.loader.enable()
        vim.opt.rtp:prepend('${ndnvimRtp}/lua')
        ${builtins.readFile ./nvim/init.lua}
        EOF
      '';
    };
  };
in pkgs.writeShellApplication {
  name = "nvim";
  runtimeInputs = runtime;
  text = ''
    ${nvim}/bin/nvim --noplugin "$@"
  '';
  meta = {
    description = "My fully configured nvim flake";
    license = pkgs.lib.licenses.mit;
    maintainers = with pkgs.lib.maintainers; [ NewDawn0 ];
    platforms = pkgs.lib.platforms.all;
  };
}
