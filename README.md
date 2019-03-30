# lightline-gitdiff

I had been using airblade/vim-gitgutter for a long time, however, I felt
distracted by the indicators in the sign column in the end. Nevertheless, I
wanted some lightweight signal telling me whether the current file contains
uncommitted changes or not.

So, this little plugin for itchyny/lightline.vim was born. By default the
plugin shows an indicator such as the following:

```
A: 4 D: 6
```

This says that there are uncommitted changes. In the current buffer 4 lines
were added and 6 lines were deleted. If there are no uncommitted changes,
nothing is shown to reduce distraction.

# Configuration

You can configure the indicators and the separator between added and deleted
lines of code. The following are the defaults:

```{vimscript}
let g:lightline#gitdiff#indicator_added = 'A: '
let g:lightline#gitdiff#indicator_deleted = 'D: '
let g:lightline#gitdiff#separator = ' '

```

# How it works

In the background, the plugin occasionally calls `git --numstat` for the
current buffer. When developing the plugin I figured that calling the command
every time lightline updates i.e., on every keystroke, is very expensive. So I
decided to cache the result and update only when really needed.

# Bugs etc.

Probably this code has some sharp edges. Feel free to report bugs, suggestions
and pull requests. I'll try to fix them as soon as possible.
