" Cache stores the information got from `git --numstat`. The key is the buffer
" number, the value is the amount of lines.
let g:lightline#gitdiff#cache = {}

augroup lightline#gitdiff
  autocmd!
  " Use a hard write b/c buffer is new or changed
  autocmd BufReadPost,BufWritePost * :call lightline#gitdiff#write_to_cache(v:false) | :call lightline#update()
  " Soft write is possible b/c no buffer new or changed
  autocmd BufEnter * :call lightline#gitdiff#write_to_cache(v:true) | :call lightline#update()
augroup end
