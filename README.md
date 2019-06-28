# vim-tabws
TabWS - a tabpage based workspace solution for vim

This vim/neovim plugin allows you to treat tabs as 'project workspaces'. It allows you to have multiple projects open in a single vim instance, and to switch between them easily. This is much better than having multiple vim instances open in various tmux/shell windows.

In particular, TabWS does the following:
  - Automatically determines project-root (using [vim-projectroot](https://github.com/dbakker/vim-projectroot)) when opening a  file. If the project-root is already open in a tab, it associated the new buffer with that 'project' tab. If the project is not open, a new tab is created to hold it.
  - Switches the current working directory to the project-root when you switch to a given tab.
  - Maintains separate tag-stacks for each project, so you can easily navigate via ctrl-]/ctrl-T in each project independently.
  - Shows the project name (i.e. the project-root name) in the tabline.
  - Replaces the :buffers, :ls commands to allow listing only the buffers associated with a given project tab.
  - Replaces the :buffer command to jump to the buffer in it's existing tab. Autocomplete of buffer names is only from those associated with the current tab.
  - Hooks into [fzf.vim](https://github.com/junegunn/fzf.vim) to make its Buffers command only display buffers from the current tab. (Requires [this](https://github.com/junegunn/fzf.vim/pull/831) pull request).
  - Adds a Tabs fzf command which lists the available tab projects for quick jumping between them.
  - Integrates with [vim-airline](https://github.com/vim-airline/vim-airline] to provide a pretty tabline (with [this](https://github.com/vim-airline/vim-airline/pull/1938) pull request).
  
## Dependencies:
  - unstable neovim (possibly also unstable vim) for settagstack/getstagstack support
  - [vim-projectroot](https://github.com/dbakker/vim-projectroot)
  - [vim-alias](https://github.com/Konfekt/vim-alias) for aliasing the :buffers, :ls and :buffer commands
  - [fzf.vim](https://github.com/junegunn/fzf.vim) 
  
## Installation
Use your favorite plugin engine to install the dependencies and the vim-tabws plugin. For Plug:
```
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'Konfekt/vim-alias'
Plug 'dbakker/vim-projectroot'
Plug 's1341/vim-tabws'
```
