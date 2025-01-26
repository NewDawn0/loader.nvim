# Here should be neovim's plugins, they when added to loader.nvim they are lazily loaded on the event you set
{ pkgs }:
with pkgs.vimPlugins; [
  vim-startuptime
  comment-nvim
  nvim-treesitter
  nvim-web-devicons
]
