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
function! lightline#gitdiff#algorithm#parse_indicator_group(indicators) abort
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
