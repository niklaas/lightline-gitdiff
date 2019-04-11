function! lightline#gitdiff#get() abort
  return lightline#gitdiff#format(g:lightline#gitdiff#cache[bufnr('%')])
endfunction

" update() {{{1 writes the diff of the current buffer to the cache and calls a
" callback function afterwards if it exists. The callback function can be
" defined in `g:lightline#gitdiff#update_callback`.
function! lightline#gitdiff#update(soft)
  call s:write_diff_to_cache(a:soft)

  let l:callback = get(g:, 'lightline#gitdiff#update_callback', 'lightline#update')

  if exists('*' . l:callback)
    execute 'call ' . l:callback . '()'
  endif
endfunction

" write_diff_to_cache() {{{1 writes the information got from `git --numstat`
" into the cache. There is an option to perform a "soft" write to reduce calls
" to `git` when needed. Anyway, the function ensures that there is data in the
" cache for the current buffer.
function! s:write_diff_to_cache(soft) abort
  if a:soft && has_key(g:lightline#gitdiff#cache, bufnr('%'))
    " b/c there is something in the cache already
    return 
  endif

  " NOTE: Don't expose `g:lightline#gitdiff#algorithm` as public API yet. I'll
  " probably re-structure the plugin and `...#algorithm` will be put in some
  " `...#library`...
  let l:Calculation = get(g:, 'lightline#gitdiff#algorithm',
        \ { -> lightline#gitdiff#algorithms#word_diff_porcelain#calculate() })
  let g:lightline#gitdiff#cache[bufnr('%')] = l:Calculation()
endfunction

" format() {{{1 returns how many lines were added, deleted and/or modified in
" a nicely formatted string. The output can be configured with the following
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
