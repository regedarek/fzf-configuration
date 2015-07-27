" fzf buffers
let s:fzf_buffers = []

function! FzfBufEntered()
  " move the current buffer to the top of the list
  let l:name = resolve(expand("<afile>"))
  if name != "" && name !~ "NERD_tree_.*"
    let l:i = index(s:fzf_buffers, name)
    if i != -1
      call remove(s:fzf_buffers, i)
    endif
    let s:fzf_buffers = insert(s:fzf_buffers, name)
  endif
endfunction

function! FzfBufDeleted()
  " remove the buffer being deleted from the list
  let l:name = resolve(expand("<afile>"))
  if name != ""
    let l:idx = index(s:fzf_buffers, name)
    if idx != -1
      call remove(s:fzf_buffers, idx)
    endif
  endif
endfunction

augroup fzfbuf
  autocmd!
  autocmd BufAdd,BufEnter * call FzfBufEntered()
  autocmd BufDelete * call FzfBufDeleted()
augroup END

command! FZFBuffers call fzf#run({
  \'source': s:fzf_buffers,
  \'sink' : 'e ',
  \'options' : '-m',
  \'tmux_height' : 8,
  \})

" fzf mru
command! FZFMru call fzf#run({
            \'source': v:oldfiles,
            \'sink' : 'e ',
            \'options' : '-m',
            \})

" fzf search lines
function! s:line_handler(l)
  let keys = split(a:l, ':\t')
  exec 'buf' keys[0]
  exec keys[1]
  normal! ^zz
endfunction

function! s:buffer_lines()
  let res = []
  for b in filter(range(1, bufnr('$')), 'buflisted(v:val)')
    call extend(res, map(getbufline(b,0,"$"), 'b . ":\t" . (v:key + 1) . ":\t" . v:val '))
  endfor
  return res
endfunction

command! FZFLines call fzf#run({
\   'source':  <sid>buffer_lines(),
\   'sink':    function('<sid>line_handler'),
\   'options': '--extended --nth=3..',
\   'down':    '60%'
\})

" fzf ag
function! s:ag_to_qf(line)
  let parts = split(a:line, ':')
  return {'filename': parts[0], 'lnum': parts[1], 'col': parts[2],
        \ 'text': join(parts[3:], ':')}
endfunction

function! s:ag_handler(lines)
  if len(a:lines) < 2 | return | endif

  let cmd = get({'ctrl-x': 'split',
               \ 'ctrl-v': 'vertical split',
               \ 'ctrl-t': 'tabe'}, a:lines[0], 'e')
  let list = map(a:lines[1:], 's:ag_to_qf(v:val)')

  let first = list[0]
  execute cmd escape(first.filename, ' %#\')
  execute first.lnum
  execute 'normal!' first.col.'|zz'

  if len(list) > 1
    call setqflist(list)
    copen
    wincmd p
  endif
endfunction

command! -nargs=* Ag call fzf#run({
\ 'source':  printf('ag --nogroup --column --color --smart-case "%s"',
\                   escape(empty(<q-args>) ? '^(?=.)' : <q-args>, '"\')),
\ 'sink*':    function('<sid>ag_handler'),
\ 'options': '--ansi --expect=ctrl-t,ctrl-v,ctrl-x '.
\            '--multi --bind ctrl-a:select-all,ctrl-d:deselect-all '.
\            '--color hl:68,hl+:110',
\ 'down':    '50%'
\ })
