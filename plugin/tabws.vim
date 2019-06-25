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
	autocmd! TabClosed * call s:tabws_tabclosed(expand('<afile>'))
	autocmd! BufEnter * call s:tabws_bufenter()
	autocmd! BufCreate * call s:tabws_bufcreate()
	autocmd! BufAdd * call s:tabws_bufadd()
	autocmd! BufNew * call s:tabws_bufnew()
	autocmd! VimEnter * call s:tabws_vimenter()
augroup END

command! -nargs=1 TabWSSetName call tabws#settabname(<q-args>)
command! TabWSBufferList call <SID>tabws_bufferlist()
command! -nargs=1 -complete=customlist,<SID>tabws_buffernamecomplete TabWSJumpToBuffer call <SID>tabws_jumptobufferintab(<q-args>)

if exists(':Alias')
	:Alias buffers TabWSBufferList 
	:Alias ls TabWSBufferList 
	:Alias buffer TabWSJumpToBuffer 
	:Alias -range b TabWSJumpToBuffer 
endif 

if exists("*fzf#run")
    let g:fzf_buffer_function = 'tabws#getbuffers'
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
		try
			execute "buffer " . a:buffer
		catch /E93/
			echom "More than one match for " . a:buffer	
		endtry

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
	echom "TabNew " . tabpagenr()
endfunction

function! s:tabws_tabenter()
	echom "TabEnter"
	call tabws#switchtotab(tabpagenr())
endfunction

function! s:tabws_tableave()
	echom "TabLeave"
	call tabws#savetagstack()
endfunction

function! s:tabws_tabnewentered()
	echom "TabNewEntered " . tabpagenr()
	call tabws#setup_tab(tabpagenr())
	call tabws#switchtotab(tabpagenr())
endfunction

function! s:tabws_tabclosed(tabnum)
	echom "TabClosed " . a:tabnum
	call tabws#deletedirectoryentryfortab(a:tabnum)
endfunction

function! s:tabws_bufenter()
	echo "BufEnter"
	call tabws#associatebufferwithtab(tabpagenr(), tabws#getcurrentbuffer(tabpagenr()))
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
	echom "VimEnter " . tabpagenr(). ': ' . bufnr('$')

	if bufnr('$') >= 1
	    call tabws#associatebufferwithtab(tabpagenr(), 1)
	    call tabws#setup_tab(tabpagenr())
	endif
	for buffer in range(2,bufnr('$'))
		let foundtab = 0
		for tab in range(1, tabpagenr('$'))
		    echom projectroot#guess(bufname(buffer)). ": " . tabws#getprojectroot(tab)
		    if projectroot#guess(bufname(buffer)) == tabws#getprojectroot(tab)
			call tabws#associatebufferwithtab(tab, buffer)
			let foundtab = 1
			break
		    endif
		endfor
		echom "foundtab: " . foundtab
		if foundtab == 0
		    exec ":tabedit ". bufname(buffer)
		    call tabws#associatebufferwithtab(tabpagenr('$'), buffer)
		    call tabws#setup_tab(tabpagenr('$'))
		    exec ":" . (tabpagenr('$') - 1) . "tabp"
		endif
	endfor 
	call tabws#switchtotab(1)
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
