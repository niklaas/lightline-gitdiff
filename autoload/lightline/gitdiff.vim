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

  call system('git rev-parse --is-inside-work-tree --prefix ' . expand('%:p:h'))
  if v:shell_error
    " b/c there simply is nothing to diff to
    return ''
  endif

  let l:stats = split(system('git diff --numstat -- ' . expand('%')))

  if len(l:stats) < 2
    " b/c there are no changes made, the file is untracked or some error
    " occured
    return ''
  endif

  if join(l:stats[:1], '') !~# '^\d\+$'
    " b/c some error must have occured
    return ''
  endif

  let l:lines_added = l:stats[0] ==# '0' ? '' : s:indicator_added . l:stats[0]
  let l:lines_deleted = l:stats[1] ==# '0' ? '' : s:indicator_deleted . l:stats[1]

  return join([l:lines_added, l:lines_deleted], s:separator)
endfunction
