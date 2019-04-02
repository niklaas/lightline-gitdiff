" Cache stores the information got from `git --numstat`. The key is the buffer
" number, the value is the amount of lines.
let g:lightline#gitdiff#cache = {}

augroup lightline#gitdiff
  autocmd!
  " Update hard b/c buffer is new or changed
  autocmd BufReadPost,BufWritePost * :call lightline#gitdiff#update(v:false)
  " Soft update is possible b/c no buffer new or changed
  autocmd BufEnter * :call lightline#gitdiff#update(v:true)
augroup end
