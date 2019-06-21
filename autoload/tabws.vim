" Copyright (c) 2017 Junegunn Choi
"
" MIT License
"
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


let s:tabws_directory = {}

function! tabws#getprojectroot(path)
	return fnamemodify(a:path, ":h")
endfunction

function! tabws#getcurrentbuffer(tabnum)
	let window = tabpagewinnr(a:tabnum)
	let bufferlist = tabpagebuflist()
	return bufferlist[window - 1]
endfunction

function! tabws#createdirectoryentry(tabnum)
	let s:tabws_directory[a:tabnum] = {'buffers': []}
endfunction

function! tabws#gettabforbuffer(buffer)
	for i in range(tabpagenr('$'))
		let direntry = s:tabws_directory[i + 1]
		for bufnum in direntry["buffers"]
			if str2nr(a:buffer) == bufnum || fnamemodify(bufname(bufnum), ":p:~:.") =~ a:buffer
				return i + 1
			endif
		endfor
	endfor
endfunction

function! tabws#getdirectoryentryforbuffer(bufnum)
	return s:tabws_directory[tabws#gettabforbuffer(a:bufnum)]
endfunction

function! tabws#getbuffersfortab(tabnum)
	if has_key(s:tabws_directory, a:tabnum)
		return s:tabws_directory[a:tabnum]["buffers"]
	endif
	return []
endfunction

function! tabws#getbuffers()
	return copy(tabws#getbuffersfortab(tabpagenr()))
endfunction

function! tabws#settabname(name)
	if !has_key(s:tabws_directory, tabpagenr())
		call tabws#createdirectoryentry(tabpagenr())
	endif
	let direntry = tabws#getdirectoryentryforbuffer(tabws#getcurrentbuffer(tabpagenr()))
	let direntry["name"] = a:name
	call tabws#refreshtabline()
endfunction

function! tabws#gettabname(tabnum)
	if has_key(s:tabws_directory, a:tabnum)
		if has_key(s:tabws_directory[a:tabnum], "name")
			return s:tabws_directory[a:tabnum]["name"]
		endif
	endif
	return "unnamed"
endfunction

function! tabws#associatebufferwithtab(...)
	if a:0 == 1
		let current_buffer = a:1
	else
		let current_buffer = tabws#getcurrentbuffer(tabpagenr())
	endif
	if !buflisted(current_buffer) || !filereadable(bufname(current_buffer)) 
		return
	endif
	if !has_key(s:tabws_directory, tabpagenr())
		call tabws#createdirectoryentry(tabpagenr())
	endif
	let direntry = s:tabws_directory[tabpagenr()]
	if index(direntry["buffers"], current_buffer) == -1
		call add(direntry["buffers"], current_buffer)
	endif
endfunction

function! tabws#restoretagstack()
	if !has_key(s:tabws_directory, tabpagenr())
		call tabws#createdirectoryentry(tabpagenr())
	endif
	let direntry = s:tabws_directory[tabpagenr()]
	if has_key(direntry, "tagstack")
		call settagstack(tabpagewinnr(tabpagenr()), direntry["tagstack"])
	endif
endfunction

function! tabws#savetagstack()
	if !has_key(s:tabws_directory, tabpagenr())
		call tabws#createdirectoryentry(tabpagenr())
	endif
	let direntry = s:tabws_directory[tabpagenr()]
	let direntry["tagstack"] = gettagstack(tabpagewinnr(tabpagenr()))
endfunction

function! TabWSGenerateTabline()
	let tablinestr = ''
	let numtabs = tabpagenr('$')
	let tabs = range(numtabs)
	for i in tabs
		let tab = i + 1
		let tabname = tabws#gettabname(tab)
		let tablinestr .= '%'. tab . 'T'
		let tablinestr .= (tab == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#')
		let tablinestr .=  ' ' . tab . ': ' . tabname
	endfor
	echom tablinestr
	return tablinestr
endfunction
function! tabws#refreshtabline()
	set tabline=%!TabWSGenerateTabline()
endfunction

