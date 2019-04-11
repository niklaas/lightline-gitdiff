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
"   6. There must be one but only one '~' in *every* group.
"
" The method implements this algorithm. It is far from perfect but seems to
" work as some tests showed.
function! lightline#gitdiff#algorithm#parse_indicator_group(indicators) abort
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
