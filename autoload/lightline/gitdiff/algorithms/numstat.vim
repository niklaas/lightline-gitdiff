" calculate_numstat {{{1 queries git to get the amount of lines that were
" added and/or deleted. It returns a dict with two keys: 'A' and 'D'. 'A'
" holds how many lines were added, 'D' holds how many lines were deleted.
function! lightline#gitdiff#algorithms#numstat#calculate(buffer) abort
  if !lightline#gitdiff#utils#is_git_exectuable() || !lightline#gitdiff#utils#is_inside_work_tree()
    " b/c there is nothing that can be done here; the algorithm needs git
    return {}
  endif

  let l:stats = split(system('cd ' . expand('#' . a:buffer . ':p:h:S')
        \ . ' && git diff --no-ext-diff --numstat -- '
        \ . expand('#' . a:buffer . ':t:S')))

  if len(l:stats) < 2 || join(l:stats[:1], '') !~# '^\d\+$'
    " b/c there are no changes made, the file is untracked or some error
    " occured
    return {}
  endif

  return { 'A': l:stats[0], 'D': l:stats[1] }
endfunction
