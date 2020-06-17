" calculate_porcelain {{{1 transcodes a `git diff --word-diff=porcelain` and
" returns a dictionary that tells how many lines in the diff mean Addition,
" Deletion or Modification.
function! lightline#gitdiff#algorithms#word_diff_porcelain#calculate(buffer) abort
  if !lightline#gitdiff#utils#is_git_exectuable() || !lightline#gitdiff#utils#is_inside_work_tree(a:buffer)
    " b/c there is nothing that can be done here; the algorithm needs git
    return {}
  endif

  let l:indicator_groups = s:transcode_diff_porcelain(s:get_diff_porcelain(a:buffer))

  let l:changes = map(copy(l:indicator_groups), { idx, val ->
        \ lightline#gitdiff#algorithms#word_diff_porcelain#parse_indicator_group(val) })

  let l:lines_added = len(filter(copy(l:changes), { idx, val -> val ==# 'A' }))
  let l:lines_deleted = len(filter(copy(l:changes), { idx, val -> val ==# 'D' }))
  let l:lines_modified = len(filter(copy(l:changes), { idx, val -> val ==# 'M' }))

  return { 'A': l:lines_added, 'D': l:lines_deleted, 'M': l:lines_modified}
endfunction

" get_diff_porcelain {{{1 returns the output of git's word-diff as list. The
" header of the diff is removed b/c it is not needed.
function! s:get_diff_porcelain(buffer) abort
  let l:porcelain = systemlist('cd ' . expand('#' . a:buffer . ':p:h:S') .
        \ ' && git diff --no-ext-diff --word-diff=porcelain --unified=0 -- ' . expand('#' . a:buffer . ':t:S'))
  return l:porcelain[4:]
endfunction

" transcode_diff_porcelain() {{{1 turns a diff porcelain into a list of lists
" such as the following:
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

  return lightline#gitdiff#utils#group_at({ el -> el ==# '~' }, a:porcelain, v:true)
endfunction

" parse_indicator_group() {{{1 parses a group of indicators af a word-diff
" porcelain that describes an Addition, Delition or Modification. It returns a
" single character of either 'A', 'D', 'M' for the type of diff that is
" recorded by the group respectively. A group looks like the following:
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
"   6. There must be one but only one '~' in *every* group.
"
" The method implements this algorithm. It is far from perfect but seems to
" work as some tests showed.
function! lightline#gitdiff#algorithms#word_diff_porcelain#parse_indicator_group(indicators) abort
  let l:changer = ''

  if len(a:indicators) ==# 1 && a:indicators[0] ==# '~'
    return 'A'
  endif

  for el in a:indicators
    if l:changer ==# '' && ( el ==# '-' || el ==# '+' )
      let l:changer = el
      continue
    endif

    if l:changer ==# '+' && el ==# '~'
      return 'A'
    endif

    if l:changer ==# '-' && el ==# '~' 
      return 'D'
    endif

    if l:changer !=# el
      return 'M'
    endif
  endfor

  " b/c we should never end up here
  echoerr 'lightline#gitdiff: Error parsing indicator group: [ ' . join(a:indicators, ', ') . ' ]'
endfunction
