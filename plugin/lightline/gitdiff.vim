" Cache stores the information got from the algorithms that process the
" `diff`s. The key is the buffer number, the value is the amount of lines.
let g:lightline#gitdiff#cache = {}

augroup lightline#gitdiff
  autocmd!
  " Update hard b/c buffer is new or changed
  autocmd BufReadPost,BufWritePost * :call lightline#gitdiff#update([bufnr('%')], v:false)
  " Soft update is possible b/c no buffer new or changed
  autocmd BufEnter * :call lightline#gitdiff#update([bufnr('%')], v:true)
  " Update all cached buffers hard b/c change to repository was made
  autocmd BufDelete COMMIT_EDITMSG :call lightline#gitdiff#update(keys(g:lightline#gitdiff#cache), v:false)
augroup end
