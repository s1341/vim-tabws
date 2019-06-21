" Copyright (c) 2017 Junegunn Choi
"
" MIT License

" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if exists('g:tabws_loaded')
	finish
endif 

augroup TabWS
	autocmd! TabNew * call s:tabws_tabnew()
	autocmd! TabEnter * call s:tabws_tabenter()
	autocmd! TabLeave * call s:tabws_tableave()
	autocmd! TabNewEntered * call s:tabws_tabnewentered()
	autocmd! TabClosed * call s:tabws_tabclosed()
	autocmd! BufEnter * call s:tabws_bufenter()
	autocmd! BufCreate * call s:tabws_bufcreate()
	autocmd! BufAdd * call s:tabws_bufadd()
	autocmd! BufNew * call s:tabws_bufnew()
	autocmd! VimEnter * call s:tabws_vimenter()
augroup END

command! -nargs=+ CreateWS call s:tabws_createws(<f-args>)
command! -nargs=1 TabWSSetName call <SID>tabws_settabname(<q-args>)
command! TabWSBufferList call <SID>tabws_bufferlist()
command! -nargs=1 -complete=customlist,<SID>tabws_buffernamecomplete TabWSJumpToBuffer call <SID>tabws_jumptobufferintab(<q-args>)

if exists(':Alias')
	:Alias buffers TabWSBufferList 
	:Alias ls TabWSBufferList 
	:Alias buffer TabWSJumpToBuffer 
endif 


function! s:tabws_buffernamecomplete(ArgLead, CmdLine, CursorPos)
	let buffers = tabws#getbuffers()
	let buffernames = []
	for buffer in buffers
		call add(buffernames, fnamemodify(bufname(buffer), ":p:~:."))
	endfor
	return buffernames
endfunction

function! s:tabws_jumptobufferintab(buffer)
	let tab = tabws#gettabforbuffer(a:buffer)
	if tab != 0
		execute tab . 'tabnext'
		execute "buffer " . a:buffer
	endif
endfunction

function! s:tabws_bufferlist()
	let buffers = tabws#getbuffers()
	let output = ''
	for buffer in buffers
		let mode = ''
		if buffer == bufnr("%")
			let mode = '%'
		elseif buffer == bufnr('#')
			let mode = '#'
		endif
		if bufwinnr(buffer) != -1
			let mode .= "a"
		elseif bufloaded(buffer)
			let mode .= "h"	
		endif
		let modified = ''
		if getbufvar(buffer, '&modified')
			let modified = '+'
		endif 
		let line = 'line 0'
		if bufloaded(buffer)
			let line = 'line ' . trim(execute("let buf=bufnr('%') | exec '" . buffer . "bufdo echo '''' . line(''.'')' | exec 'b' buf"))
		endif 
		let name = ' "' . fnamemodify(bufname(buffer), ":p:~:.") . '"'
		let outputline = printf("%3s%3s%2s%2s", buffer, mode, modified, name)
		let outputline .= s:prepad(line, 45 - len(outputline), ' ')
		let output .= outputline . "\n"
	endfor
	echon output
endfunction


function! s:tabws_tabnew()
	echom "TabNew"
endfunction

function! s:tabws_tabenter()
	echom "TabEnter"
	call tabws#restoretagstack()
endfunction

function! s:tabws_tableave()
	echom "TabLeave"
	call tabws#savetagstack()
endfunction

function! s:tabws_tabnewentered()
	echom "TabNewEntered"
	call tabws#settabname(tabws#getprojectroot(bufname(tabws#getcurrentbuffer(tabpagenr()))))

endfunction

function! s:tabws_tabclosed()
	echom "TabClosed"
endfunction

function! s:tabws_bufenter()
	call tabws#associatebufferwithtab()
	call tabws#refreshtabline()
endfunction

function! s:tabws_bufcreate()
	echom "BufCreate " . tabpagenr()
endfunction

function! s:tabws_bufadd()
	echom "BufAdd " . tabpagenr()
endfunction

function! s:tabws_bufnew()
	echom "BufNew " . tabpagenr()
endfunction

function! s:tabws_vimenter()
	echom "VimEnter " . tabpagenr()
	for buffer in range(bufnr('$'))
		call tabws#associatebufferwithtab(buffer + 1)
	endfor 
endfunction
let g:tabws_loaded = 1

function! s:prepad(s,amt,...)
    if a:0 > 0
        let char = a:1
    else
        let char = ' '
    endif
    return repeat(char,a:amt - len(a:s)) . a:s
endfunction
