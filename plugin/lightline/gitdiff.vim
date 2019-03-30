let g:lightline#gitdiff#cache= ''

augroup lightline#gitdiff
  autocmd!
  autocmd BufReadPost,BufWritePost,BufEnter * :call lightline#gitdiff#set()
augroup end
