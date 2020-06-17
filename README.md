# lightline-gitdiff

I had been using [airblade/vim-gitgutter][gitgutter] for a while, however, I
felt distracted by the indicators shown in the sign column in the end. That
said, I wanted some lightweight signal indicating whether the current file
contains uncommitted changes to the repository or not.

So, this little plugin was born. I myself use
[itchyny/lightline.vim][lightline] to configure the statusline of vim easily,
so this is where the name of the plugin comes from. In addition, I embrace
lightlines's philosophy to provide a lightweight and stable, yet configurable
plugin that "just works". However, you can also integrate the plugin with vim's
vanilla `statusline`.

By default the plugin shows indicators such as the following:

```
A: 4 D: 6 M: 2
```

This says that, in comparison to the git index, the current buffer contains 12
uncommitted changes: four lines were deleted, six lines were added and two
lines only modified. If there are no uncommitted changes, nothing is shown to
reduce distraction.

You can see the plugin in action in my statusline/lightline:

![screenshot](https://raw.githubusercontent.com/wiki/niklaas/lightline-gitdiff/images/screenshot.png)

## Installation

Use your favorite plugin manager to install the plugin. I personally prefer
vim-plug but feel free to choose another one:

```vim
Plug 'niklaas/lightline-gitdiff'
```

## Configuration

### Using vim's vanilla statusline

```vim
set statusline=%!lightline#gitdiff#get()
```

which let's your `statusline` consist of `gitdiff`'s indicators only. (Probably
not what you want but you can consult `:h statusline` for further information
on how to include additional elements.)

### Using lightline

```vim
let g:lightline = {
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'filename', 'readonly', 'modified' ],
      \             [ 'gitdiff' ] ],
      \   'right': [ [ 'lineinfo' ],
      \              [ 'percent' ] ]
      \ },
      \ 'inactive': {
      \   'left': [ [ 'filename', 'gitversion' ] ],
      \ },
      \ 'component_function': {
      \   'gitbranch': 'fugitive#head',
      \ },
      \ 'component_expand': {
      \   'gitdiff': 'lightline#gitdiff#get',
      \ },
      \ 'component_type': {
      \   'gitdiff': 'middle',
      \ },
      \ }
```

which should give you pretty much the same result as shown in the screenshot.

# Configuration

You can configure the appearance of the indicators and the separator between
them. The following are the defaults:

```vim
let g:lightline#gitdiff#indicator_added = 'A: '
let g:lightline#gitdiff#indicator_deleted = 'D: '
let g:lightline#gitdiff#separator = ' '
```

A callback function is called every time the `diff` is updated and written to
the cache. By default this is `lightline#update()` to update lightline with
the newly calculated `diff`. However, you can also provide you own callback
function in the following way:

```vim
let g:lightline#gitdiff#update_callback = { -> MyCustomCallback() }
```

If the callback function is not defined, the error is caught. This allows to
use the plugin with any type of `statusline` plugin.

You can even change the algorithm that is used to calculate the `diff`. The
plugin comes bundled with two algorithms: `numstat` and `word_diff_porcelain`.
By default, the latter one is used because it allows to display modified lines.
`numstat` is much simpler but only supports showing added and deleted lines.
This resembles the default:

```vim
let g:LightlineGitDiffAlgorithm =
      \ { buffer -> lightline#gitdiff#algorithms#word_diff_porcelain#calculate(buffer) }
```

Substitute `word_diff_porcelain` with `numstat` if you want to switch -- or
provide your own. Take a look at the source of both functions for inspiration
or consult me if you need help. I am happy to bundle additional faster and more
feature-rich algorithms in the package.

You can show empty indicators (i.e. `A: 0 D: 0 M: 0`) in the following way:

```vim
let g:lightline#gitdiff#show_empty_indicators = 1
```

# How it works / performance

In the background, `lightline#gitdiff#get()` calls `git --numstat` or `git
--word-diff=porcelain` (depending on the algorithm you choose, the latter being
the default) for the current buffer and caches the result.

If possible e.g., when an already open buffer is entered, the cache is used and
no call to `git` is made. `git` is only executed when reading or writing to a
buffer. See the `augroup` in [plugin/lightline/gitdiff.vim][augroup].

If you have any suggestions to improve the performance, please let me know. I
am happy to implement your suggestions on my own -- or you can create a pull
request.

# Bugs etc.

Probably this code has some sharp edges. Feel free to report bugs, suggestions
and pull requests. I'll try to fix them as soon as possible.

[gitgutter]: https://github.com/airblade/vim-gitgutter
[lightline]: https://github.com/itchyny/lightline.vim
[augroup]: https://github.com/niklaas/lightline-gitdiff/blob/master/plugin/lightline/gitdiff.vim
