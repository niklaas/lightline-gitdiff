let s:indicator_added = get(g:, 'lightline#gitdiff#indicator_added', 'A: ')
let s:indicator_deleted = get(g:, 'lightline#gitdiff#indicator_deleted', 'D: ')
let s:separator = get(g:, 'lightline#gitdiff#separator', ' ')

function! lightline#gitdiff#get() abort
  return g:lightline#gitdiff#cache
endfunction

function! lightline#gitdiff#set() abort
  let g:lightline#gitdiff#cache = lightline#gitdiff#generate()
endfunction

function! lightline#gitdiff#generate() abort
  if !executable('git')
    " b/c cannot do anything
    return ''
  endif

  call system('git rev-parse --is-inside-work-tree')
  if v:shell_error
    " b/c there simply is nothing to diff to
    return ''
  endif

  let l:stats = split(system('git diff --numstat -- ' . expand('%')))

  if len(l:stats) == 0
    " b/c there are no changes made or the file is untracked
    return ''
  endif

  let l:lines_added = l:stats[0] ==# '0' ? '' : s:indicator_added . l:stats[0]
  let l:lines_deleted = l:stats[1] ==# '0' ? '' : s:indicator_deleted . l:stats[1]

  return join([l:lines_added, l:lines_deleted], s:separator)
endfunction
