function! lightline#gitdiff#get() abort
  return lightline#gitdiff#format(g:lightline#gitdiff#cache[bufnr('%')])
endfunction

" update writes the diff of the current buffer to the cache and calls a
" callback function afterwards if it exists. The callback function can be
" defined in `g:lightline#gitdiff#update_callback`.
function! lightline#gitdiff#update(soft)
  call s:write_diff_to_cache(a:soft)

  let l:callback = get(g:, 'lightline#gitdiff#update_callback', 'lightline#update')

  if exists('*' . l:callback)
    execute 'call ' . l:callback . '()'
  endif
endfunction

" write_diff_to_cache writes the information got from `git --numstat` into the
" cache. There is an option to perform a "soft" write to reduce calls to `git`
" when needed. Anyway, the function ensures that there is data in the cache
" for the current buffer.
function! s:write_diff_to_cache(soft) abort
  if a:soft && has_key(g:lightline#gitdiff#cache, bufnr('%'))
    " b/c there is something in the cache already
    return 
  endif

  let g:lightline#gitdiff#cache[bufnr('%')] = s:calculate()
endfunction

" format returns how many lines were added and/or deleted in a nicely
" formatted string. The output can be configured with global variables.
function! lightline#gitdiff#format(data) abort
  let l:indicator_added = get(g:, 'lightline#gitdiff#indicator_added', 'A: ')
  let l:indicator_deleted = get(g:, 'lightline#gitdiff#indicator_deleted', 'D: ')
  let l:separator = get(g:, 'lightline#gitdiff#separator', ' ')

  let l:lines_added = has_key(a:data, 'A') ? l:indicator_added . a:data['A'] : ''
  let l:lines_deleted = has_key(a:data, 'D') ? l:indicator_deleted . a:data['D'] : ''

  return join([l:lines_added, l:lines_deleted], l:separator)
endfunction

" calculate queries git to get the amount of lines that were added and/or
" deleted. It returns a dict with two keys: 'A' and 'D'. 'A' holds how many
" lines were added, 'D' holds how many lines were deleted.
"
" This function is the most expensive one. It calls git twice: to check
" whether the buffer is in a git repository and to do the actual calculation.
function! s:calculate() abort
  if !executable('git') || !s:is_inside_work_tree()
    " b/c cannot do anything
    return {}
  endif

  let l:stats = split(system('cd ' . expand('%:p:h:S') . ' && git diff --numstat -- ' . expand('%:t:S')))

  if len(l:stats) < 2 || join(l:stats[:1], '') !~# '^\d\+$'
    " b/c there are no changes made, the file is untracked or some error
    " occured
    return {}
  endif

  let l:ret = {}

  " lines added
  if l:stats[0] !=# '0'
    let l:ret['A'] = l:stats[0]
  endif

  " lines deleted
  if l:stats[1] !=# '0'
    let l:ret['D'] = l:stats[1]
  endif

  return l:ret
endfunction

function! s:is_inside_work_tree() abort "{{{
  call system('cd ' . expand('%:p:h:S') . ' && git rev-parse --is-inside-work-tree --prefix ' . expand('%:h:S'))
  return !v:shell_error
endfunction
