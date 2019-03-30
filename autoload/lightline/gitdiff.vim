function! lightline#gitdiff#get() abort
  return g:lightline#gitdiff#cache
endfunction

function! lightline#gitdiff#set() abort
  let g:lightline#gitdiff#cache = lightline#gitdiff#generate()
endfunction

function! lightline#gitdiff#generate() abort
  let l:indicator_added = get(g:, 'lightline#gitdiff#indicator_added', 'A: ')
  let l:indicator_deleted = get(g:, 'lightline#gitdiff#indicator_deleted', 'D: ')
  let l:separator = get(g:, 'lightline#gitdiff#separator', ' ')

  if !executable('git') || !lightline#gitdiff#is_inside_work_tree()
    " b/c cannot do anything
    return ''
  endif

  let l:stats = split(system('cd ' . expand('%:p:h:S') . ' && git diff --numstat -- ' . expand('%:t:S')))

  if len(l:stats) < 2 || join(l:stats[:1], '') !~# '^\d\+$'
    " b/c there are no changes made, the file is untracked or some error
    " occured
    return ''
  endif

  let l:lines_added = l:stats[0] ==# '0' ? '' : l:indicator_added . l:stats[0]
  let l:lines_deleted = l:stats[1] ==# '0' ? '' : l:indicator_deleted . l:stats[1]

  return join([l:lines_added, l:lines_deleted], l:separator)
endfunction

function! lightline#gitdiff#is_inside_work_tree() abort
  call system('cd ' . expand('%:p:h:S') . ' && git rev-parse --is-inside-work-tree --prefix ' . expand('%:h:S'))
  return !v:shell_error
endfunction
