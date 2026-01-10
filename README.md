> [!WARNING]  
> This project should be considered unstable, breaking changes can and will 
> happen at any time.

# wip.nvim

wip.nvim is a minimalistic plugin simplifying setting up language specific 
treesitters, language servers and formatters. 

## Features

- A json config file that you can use to simply configure the langauges you use
  in neovim.
- Setup of treesitters per language specified
- Setup of lsps based on the configs in the 
  [nvim-lspconfig repo](https://github.com/neovim/nvim-lspconfig/)
- Setup of formatters supported by 
  [conform.nvim](https://github.com/stevearc/conform.nvim)

## Example config

Right now the config file has to be called `wip.config.json` and be placed in 
your nvim config folder (e.g. `$HOME/.config/nvim`) but that is subject to 
swift change in the future.

Take a look at the [example](examples/wip.config.json) in the examples folder.


## What something else?

Add something in the discussion, there are no issues in the project.
