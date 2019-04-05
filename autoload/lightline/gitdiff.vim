function! lightline#gitdiff#get() abort
  return lightline#gitdiff#format(g:lightline#gitdiff#cache[bufnr('%')])
endfunction

" write_to_cache writes the information got from `git --numstat` into the
" cache. There is an option to perform a "soft" write to reduce calls to `git`
" when needed. Anyway, the function ensures that there is data in the cache
" for the current buffer.
function! lightline#gitdiff#write_to_cache(soft) abort
  if a:soft && has_key(g:lightline#gitdiff#cache, bufnr('%'))
    " b/c there is something in the cache already
    return 
  endif

  " let g:lightline#gitdiff#cache[bufnr('%')] = s:calculate_numstat()
  let g:lightline#gitdiff#cache[bufnr('%')] = s:calculate_porcelain()
endfunction

" format returns how many lines were added and/or deleted in a nicely
" formatted string. The output can be configured with global variables.
function! lightline#gitdiff#format(data) abort
  let l:indicator_added = get(g:, 'lightline#gitdiff#indicator_added', 'A: ')
  let l:indicator_deleted = get(g:, 'lightline#gitdiff#indicator_deleted', 'D: ')
  let l:indicator_modified = get(g:, 'lightline#gitdiff#indicator_modified', 'M: ')
  let l:separator = get(g:, 'lightline#gitdiff#separator', ' ')

  let l:lines_added = has_key(a:data, 'A') ? l:indicator_added . a:data['A'] : ''
  let l:lines_deleted = has_key(a:data, 'D') ? l:indicator_deleted . a:data['D'] : ''
  let l:lines_modified = has_key(a:data, 'M') ? l:indicator_modified . a:data['M'] : ''

  return join([l:lines_added, l:lines_deleted, l:lines_modified], l:separator)
endfunction

" calculate_numstat queries git to get the amount of lines that were added and/or
" deleted. It returns a dict with two keys: 'A' and 'D'. 'A' holds how many
" lines were added, 'D' holds how many lines were deleted.
"
" This function is the most expensive one. It calls git twice: to check
" whether the buffer is in a git repository and to do the actual calculation.
function! s:calculate_numstat() abort
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

function! s:calculate_porcelain() abort
  let l:indicator_groups = s:transcode_diff_porcelain(s:get_diff_porcelain())

  let l:indicators = map(copy(l:indicator_groups), { idx, val -> s:parse_indicator_group(val) })

  let l:lines_added = len(filter(copy(l:indicators), { idx, val -> val ==# 'A' }))
  let l:lines_deleted = len(filter(copy(l:indicators), { idx, val -> val ==# 'D' }))
  let l:lines_modified = len(filter(copy(l:indicators), { idx, val -> val ==# 'M' }))

  let l:ret = {}

  if l:lines_added > 0
    let l:ret['A'] = l:lines_added
  endif

  if l:lines_deleted > 0
    let l:ret['D'] = l:lines_deleted
  endif

  if l:lines_modified > 0
    let l:ret['M'] = l:lines_modified
  endif

  return l:ret
endfunction

" get_diff_porcelain returns the output of git's word-diff as list. The header
" of the diff is removed b/c it is not needed.
function! s:get_diff_porcelain() abort
  " return the ouput of `git diff --word-diff=porcelain --unified=0` linewise
  "
  let l:porcelain = systemlist('cd ' . expand('%:p:h:S') . ' && git diff --word-diff=porcelain --unified=0 -- ' . expand('%:t:S'))
  return l:porcelain[4:]
endfunction

" transcode_diff_porcelain turns a diff porcelain into a list of lists such as
" the following:
"
"   [ [' ', '-', '~'], ['~'], ['+', '~'], ['+', '-', '~' ] ]
"
" This translates to Deletion, Addition, Addition and Modification. The
" characters ' ', '-', '+', '~' are the very first columns of a
" `--word-diff=porcelain` output and include everything we need for
" calculation.
function! s:transcode_diff_porcelain(porcelain) abort
  " b/c we do not need the line identifiers
  call filter(a:porcelain, { idx, val -> val !~# '^@@' })

  " b/c we only need the identifiers at the first char of each diff line
  call map(a:porcelain, { idx, val -> strcharpart(val, -1, 2) })

  return s:group_at_right({ el -> el ==# '~' }, a:porcelain, v:true)
endfunction

" parse_indicator_group parses a group of indicators af a word-diff porcelain
" that describes an Addition, Delition or Modification. It returns a single
" character of either 'A', 'D', 'M' for the type of diff that is recorded by
" the group.
function! s:parse_indicator_group(indicators) abort
  let l:action = ''  " A_ddition, D_eletion or M_odification
  let l:changer = ''

  for el in a:indicators
    if el ==# ' ' && l:changer ==# ''
      " b/c first element with no meaning
      continue
    endif

    if el ==# '+' || el ==# '-'
      if l:changer ==# ''
        " changer was found
        let l:changer = el
        continue
      else
        " 2nd changer found i.e., modification
        return 'M'
      endif
    endif

    if el ==# '~'
      if l:changer ==# '' || l:changer ==# '+'
        " a single `~` stands for a new line i.e., an addition
        return 'A'
      else
        " b/c changer must be '-'
        return 'D'
      endif
    endif
  endfor

  " b/c we should never end up here
  echoerr 'Could not parse indicator group of word-diff porcelain'
endfunction

" group_at groups a list of elements where `f` evaluates to true returning a
" list of lists. `f` must take a single parameter; each element is used as an
" argument to `f`. If `borders` is true, the matched element is included in
" each group at the beginning.
function! s:group_at(f, list, borders) abort
  let grouped_list = []

  for el in a:list
    if a:f(el)
      call add(l:grouped_list, [])
      if !a:borders
        continue
      endif
    endif

    call add(l:grouped_list[len(l:grouped_list)], el)
  endfor

  return grouped_list
endfunction

" group_at_right behaves the same as group_at except that the matched element
" is included in each group /at the end/.
function! s:group_at_right(f, list, borders) abort
  return reverse(s:group_at(a:f, reverse(a:list), a:borders))
endfunction

function! s:is_inside_work_tree() abort "{{{
  call system('cd ' . expand('%:p:h:S') . ' && git rev-parse --is-inside-work-tree --prefix ' . expand('%:h:S'))
  return !v:shell_error
endfunction
