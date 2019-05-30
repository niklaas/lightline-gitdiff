" group_at() {{{1 groups a list of elements where `f` evaluates to true returning a
" list of lists. `f` must take a single parameter; each element is used as an
" argument to `f`. If `borders` is true, the matched element is included in
" each group at the end.
function! lightline#gitdiff#utils#group_at(f, list, borders) abort
  " for the first element this must be true to initialise the list with an
  " empty group at the beginning (if it's not a border that should be
  " excluded)
  let l:is_previous_border = v:true
  let l:grouped_list = []

  for el in a:list
    " element matches but not borders should be included
    let l:skip_this = a:f(el) && !a:borders

    if l:is_previous_border && !l:skip_this
      call add(l:grouped_list, [])
    endif

    let l:is_previous_border = a:f(el) ? v:true : v:false

    if l:skip_this
      continue
    endif

    call add(l:grouped_list[len(l:grouped_list)-1], el)
  endfor

  return l:grouped_list
endfunction

function! lightline#gitdiff#utils#is_inside_work_tree(buffer) abort "{{{1
  call system('cd ' . expand('#' . a:buffer . ':p:h:S') . ' && git rev-parse --is-inside-work-tree --prefix ' . expand('#' . a:buffer . ':h:S'))
  return !v:shell_error
endfunction

function! lightline#gitdiff#utils#is_git_exectuable() abort "{{{1
  return executable('git')
endfunction
