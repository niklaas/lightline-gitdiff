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

  let l:F = get(g:, 'lightline#gitdiff#algorithm', { -> s:calculate_porcelain() })
  let g:lightline#gitdiff#cache[bufnr('%')] = l:F()
endfunction

" format returns how many lines were added, deleted and/or modified in a
" nicely formatted string. The output can be configured with the following
" global variables that are exposed as public API:
"
" - lightline#gitdiff#separator
" - lightline#gitdiff#indicator_added
" - lightline#gitdiff#indicator_deleted
" - lightline#gitdiff#indicator_modified
"
" It takes what I call "diff_dict" as input i.e., a Dict that has identifiers
" as keys (`A`, `D`, `M`, ...) and the amount of changes as values. If none of
" the global variables are set, `format` returns a joined string seprated by a
" single space with the amount of each type of change prefixed with its key
" and a colon e.g., `A: 4 D: 5`.
function! lightline#gitdiff#format(diff_dict) abort
  let l:separator = get(g:, 'lightline#gitdiff#separator', ' ')

  let l:diff_dict_mapping = { 'A': 'added', 'D': 'deleted', 'M': 'modified' }
  let l:DiffDictKeyValueFormatter = { key, val -> has_key(a:diff_dict, key) ?
        \ get(g:, 'lightline#gitdiff#indicator_' . val, key . ': ') . a:diff_dict[key] : '' }

  return join(values(filter(map(l:diff_dict_mapping, l:DiffDictKeyValueFormatter),
        \ { key, val -> val !=# '' })), l:separator)
endfunction

" calculate_numstat queries git to get the amount of lines that were added and/or
" deleted. It returns a dict with two keys: 'A' and 'D'. 'A' holds how many
" lines were added, 'D' holds how many lines were deleted.
"
" This function is the most expensive one. It calls git twice: to check
" whether the buffer is in a git repository and to do the actual calculation.
function! s:calculate_numstat() abort
  if !s:is_git_exectuable() || !s:is_inside_work_tree()
    " b/c there is nothing that can be done
    return
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

" calculate_porcelain transcodes a `git diff --word-diff=porcelain` and
" returns a dictionary that tells how many lines in the diff mean Addition,
" Deletion or Modification.
function! s:calculate_porcelain() abort
  let l:indicator_groups = s:transcode_diff_porcelain(s:get_diff_porcelain())

  let l:changes = map(copy(l:indicator_groups), { idx, val -> s:parse_indicator_group(val) })

  let l:lines_added = len(filter(copy(l:changes), { idx, val -> val ==# 'A' }))
  let l:lines_deleted = len(filter(copy(l:changes), { idx, val -> val ==# 'D' }))
  let l:lines_modified = len(filter(copy(l:changes), { idx, val -> val ==# 'M' }))

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
  if !s:is_git_exectuable() || !s:is_inside_work_tree()
    " b/c there is nothing that can be done
    return
  endif

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
" This translates to Deletion, Addition, Addition and Modification eventually,
" see s:parse_indicator_group. The characters ' ', '-', '+', '~' are the very
" first columns of a `--word-diff=porcelain` output and include everything we
" need for calculation.
function! s:transcode_diff_porcelain(porcelain) abort
  " b/c we do not need the line identifiers
  call filter(a:porcelain, { idx, val -> val !~# '^@@' })

  " b/c we only need the identifiers at the first char of each diff line
  call map(a:porcelain, { idx, val -> strcharpart(val, -1, 2) })

  return s:group_at({ el -> el ==# '~' }, a:porcelain, v:true)
endfunction

" parse_indicator_group parses a group of indicators af a word-diff porcelain
" that describes an Addition, Delition or Modification. It returns a single
" character of either 'A', 'D', 'M' for the type of diff that is recorded by
" the group respectively. A group looks like the following:
"
"   [' ', '+', '~']
"
" In this case it means A_ddition. The algorithm is rather simple because
" there are only four indicators: ' ', '+', '-', '~'. These are the rules:
"
"   1. Sometimes a group starts with a 'space'. This can be ignored.
"   2. '+' and '-' I call "changers". In combination with other indicators
"      they specify what kind of change was made.
"   3. If a '+' or '-' is follwed by a '~' the group means Addition or
"      Deletion respectively.
"   4. If a '+' or '-' is followed by anything else than a '~' it is a
"      Modification.
"   5. If the group consists of a single '~' it is an Addition.
"
" The method implements this algorithm. It is far from perfect but seems to
" work as some tests showed.
function! s:parse_indicator_group(indicators) abort
  let l:action = ''  " A_ddition, D_eletion or M_odification
  let l:changer = ''

  for el in a:indicators
    if el ==# ' ' && l:changer ==# ''
      " b/c first element with no meaning
      continue
    endif

    if el ==# '+' || el ==# '-' && l:changer ==# ''
      " changer found
      let l:changer = el
      continue
    endif

    if el ==# '~' && l:changer ==# ''
      return 'A'
    endif

    if el ==# '~' && l:changer ==# '+'
      return 'A'
    endif

    if el ==# '~' && l:changer ==# '-'
      return 'D'
    endif

    return 'M'
  endfor

  " b/c we should never end up here
  echoerr 'lightline#gitdiff: Could not parse indicator group of word-diff porcelain: ' . join(a:indicators, ', ')
endfunction

" group_at groups a list of elements where `f` evaluates to true returning a
" list of lists. `f` must take a single parameter; each element is used as an
" argument to `f`. If `borders` is true, the matched element is included in
" each group at the end.
function! s:group_at(f, list, borders) abort "{{{1
  " for the first element this must be true to initialise the list with an
  " empty group at the beginning
  let l:is_previous_border = v:true
  let l:grouped_list = []

  for el in a:list
    if l:is_previous_border
      call add(l:grouped_list, [])
    endif

    let l:is_previous_border = a:f(el) ? v:true : v:false

    if !a:borders
      continue
    endif

    call add(l:grouped_list[len(l:grouped_list)-1], el)
  endfor

  return l:grouped_list
endfunction

function! s:is_inside_work_tree() abort "{{{1
  call system('cd ' . expand('%:p:h:S') . ' && git rev-parse --is-inside-work-tree --prefix ' . expand('%:h:S'))
  return !v:shell_error
endfunction

function! s:is_git_exectuable() abort "{{{1
  return executable('git')
endfunction
