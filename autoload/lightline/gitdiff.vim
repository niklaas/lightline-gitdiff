function! lightline#gitdiff#get() abort
  return lightline#gitdiff#format(g:lightline#gitdiff#cache[bufnr('%')])
endfunction

" update() {{{1 is the entry point for *writing* changes of the current buffer
" into the cache. It calls a callback function afterwards. This allows to
" execute arbitrary code every time the cache was updated.
"
" By default, `lightline#update()` is called b/c this plugin was intended for
" Lightline [1] originally. However, /there is no need to use Lightline/.
" Since a callback is provided, you can update any other statusbar et al.
"
" If the provided callback cannot be found, the error is caught.
"
" [1]: https://github.com/itchyny/lightline.vim
function! lightline#gitdiff#update(buffers, soft)
  for buffer in a:buffers
    call lightline#gitdiff#write_calculation_to_cache(buffer, a:soft)
  endfor

  let l:Callback = get(g:, 'lightline#gitdiff#update_callback', { -> lightline#update() })

  try
    call l:Callback()
  catch /^Vim\%((\a\+)\)\=:E117/
  endtry
endfunction

" write_calculation_to_cache() {{{1 writes the information got from an
" algorithm that calculates changes into the cache. There is an option to
" perform a "soft" write to reduce calls to the function that calculates
" changes. This is to minimize overhead. Anyway, the function ensures that
" there is data in the cache for the current buffer.
function! lightline#gitdiff#write_calculation_to_cache(buffer, soft) abort
  if a:soft && has_key(g:lightline#gitdiff#cache, a:buffer)
    " b/c there is something in the cache already
    return
  endif

  let l:indicator_values = get(g:, 'LightlineGitDiffAlgorithm',
      \ { buffer -> lightline#gitdiff#algorithms#word_diff_porcelain#calculate(buffer) })(a:buffer)

  " If the user doesn't want to show empty indicators,
  "     then remove the empty indicators returned from the algorithm
  if !get(g:, 'lightline#gitdiff#show_empty_indicators', 0)
    for key in keys(l:indicator_values)
      if l:indicator_values[key] == 0
        unlet l:indicator_values[key]
      endif
    endfor
  endif

  let g:lightline#gitdiff#cache[a:buffer] = l:indicator_values
endfunction

" format() {{{1 returns the calculated changes of the current buffer in a
" nicely formatted string. The output can be configured with the following
" global variables that are exposed as public API:
"
" - lightline#gitdiff#separator
" - lightline#gitdiff#indicator_added
" - lightline#gitdiff#indicator_deleted
" - lightline#gitdiff#indicator_modified
"
" It takes what I call "diff_dict" as input i.e., a Dict that has identifiers
" as keys (`A`, `D` and `M`). Each identifier specifies a type of change. The
" values of the dict specify the amount of changes. The following types of
" changes exist:
"
" - A: Addition
" - D: Deletion
" - M: Modification
"
" In fact, an arbitrary number of changes can be supported. This depends on
" the algorithm that is used for calculation
" (`g:LightlineGitDiffAlgorithm`). However, this function takes only these
" types of changes into account b/c it only provides default indicators for
" these types. If an algorithm does not support a particular type, this is not
" an issue; if it supports more types than this function, the additional types
" must be configured with default values here.
"
" The function maps the values of the diff_dict to the indicators that are
" configured with the global values mentioned above. The `...#separator`
" separates each indicator-value-pair. If none of the global variables are
" set, `format` returns a joined string separates by a single space with the
" amount of each type of change prefixed with its key and a colon e.g., `A: 4
" D: 5`.
function! lightline#gitdiff#format(diff_dict) abort
  let l:separator = get(g:, 'lightline#gitdiff#separator', ' ')

  let l:change_types = { 'A': 'added', 'D': 'deleted', 'M': 'modified' }
  let l:Formatter = { key, val -> has_key(a:diff_dict, key) ?
        \ get(g:, 'lightline#gitdiff#indicator_' . val, key . ': ') . a:diff_dict[key] : '' }

  return join(values(filter(map(l:change_types, l:Formatter),
        \ { key, val -> val !=# '' })), l:separator)
endfunction
