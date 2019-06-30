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

function! tabws#getprojectroot(tabnum)
	let direntry = tabws#getdirectoryentryfortab(a:tabnum)
	if has_key(direntry, "projectroot")
		return direntry["projectroot"]
	endif
	return ""
endfunction

function! tabws#setprojectroot(tabnum, projectroot)
	let direntry = tabws#getdirectoryentryfortab(a:tabnum)
	let direntry["projectroot"] = a:projectroot
endfunction

function! tabws#getcurrentbuffer(tabnum)
	let window = tabpagewinnr(a:tabnum)
	let bufferlist = tabpagebuflist()
	return bufferlist[window - 1]
endfunction 

function! tabws#setup_tab(tabnum)
	if has_key(s:tabws_directory, a:tabnum) && a:tabnum < tabpagenr('$')
		for tab in range(tabpagenr('$'), a:tabnum + 1, -1)
			let direntry = tabws#getdirectoryentryfortab(tab - 1)
			call remove(s:tabws_directory, tab -1)
			let s:tabws_directory[tab] = direntry
		endfor
	endif
	if !has_key(s:tabws_directory, a:tabnum)
		call tabws#createdirectoryentry(a:tabnum)
	endif
	let current_buffer = tabws#getcurrentbuffer(a:tabnum)
	if bufname(current_buffer) != ""
		let projectroot = projectroot#guess(bufname(current_buffer))
		call tabws#setprojectroot(a:tabnum, projectroot)
		call tabws#settabname(a:tabnum, fnamemodify(projectroot, ":t"))
	endif
endfunction

function! tabws#jumptobufferintab(buffer)
	let tab = tabws#gettabforbuffer(a:buffer)
	"echom "jumping to buffer " . a:buffer . "in tab: " . tab
	if tab != 0
		exec ":" . tab . 'tabnext'
		try
			exec ":buffer " . a:buffer
		catch /E93/
			echom "More than one match for " . a:buffer	
		endtry

	endif
endfunction

function! tabws#jumptotab(tab)
	exec ":" . a:tab . "tabnext"
	exec ":buffer " . tabws#getcurrentbufferfortab(a:tab)
endfunction

function! tabws#findtabbyprojectroot(projectroot)
	for tab in range(1, tabpagenr('$'))
	    	if a:projectroot == tabws#getprojectroot(tab)
			return tab
	    	endif
	endfor
	return -1
endfunction

function! tabws#setup_buffer(bufnum)
	if bufname(a:bufnum) == ""
		return -1
	endif
	let tab = tabws#findtabbyprojectroot(projectroot#guess(fnamemodify(bufname(a:bufnum), ":p:~:.")))
	"echom "found tab by project root: " . tab . " for bufname: " . fnamemodify(bufname(a:bufnum), ":p:~:.")
	if tab == -1
	    	exec ":tabedit ". bufname(a:bufnum)
	    	call tabws#setup_tab(tabpagenr('$'))
	    	call tabws#associatebufferwithtab(tabpagenr('$'), a:bufnum)
		call tabws#setcurrentbufferfortab(tabpagenr('$'), a:bufnum)
		return tabpagenr('$')
	else
		call tabws#associatebufferwithtab(tab, a:bufnum)
	endif
	call tabws#setcurrentbufferfortab(tab, a:bufnum)
	return tab
endfunction

function! tabws#switchtotab(tabnum)
	"echom "switching to tab " . a:tabnum
	call tabws#restoretagstack()
	let path = tabws#getprojectroot(a:tabnum)
	if path != ""
		execute(":cd " . path)
	endif
endfunction 

function! tabws#getcurrentbufferfortab(tabnum)
	let direntry = tabws#getdirectoryentryfortab(a:tabnum)
	return direntry['current_buffer']
endfunction

function! tabws#setcurrentbufferfortab(tabnum, bufnum)
	let direntry = tabws#getdirectoryentryfortab(a:tabnum)
	let direntry['current_buffer'] = a:bufnum
endfunction

function! tabws#createdirectoryentry(tabnum)
	let s:tabws_directory[a:tabnum] = {'buffers': [], 'current_buffer': 0}
endfunction

function! tabws#gettabforbuffer(buffer)
	for i in range(1, tabpagenr('$'))
		if has_key(s:tabws_directory, i)
			let direntry = s:tabws_directory[i]
			for bufnum in direntry["buffers"]
				if str2nr(a:buffer) == bufnum || substitute(fnamemodify(bufname(bufnum), ":p:~:."), '~', '\~', '') =~ substitute(a:buffer, '~', '\~', '')
					return i
				endif
			endfor
		endif
	endfor
	return 0
endfunction

function! tabws#getdirectoryentryfortab(tabnum)
	if !has_key(s:tabws_directory, a:tabnum) 
		call tabws#createdirectoryentry(a:tabnum)
	endif
	return s:tabws_directory[a:tabnum]
endfunction

function! tabws#deletedirectoryentryfortab(tabnum)
	if a:tabnum <= tabpagenr('$') + 1
		for tabtomove in range(a:tabnum + 1, tabpagenr('$') + 1)
			let direntry = tabws#getdirectoryentryfortab(tabtomove)
			call remove(s:tabws_directory, tabtomove)
			let s:tabws_directory[tabtomove - 1] = direntry
		endfor
	endif
endfunction

function! tabws#getdirectoryentryforbuffer(bufnum)
	let tab = tabws#gettabforbuffer(a:bufnum)
	return tabws#getdirectoryentryfortab(tab)
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

function! tabws#settabname(tabnum, name)
	let direntry = tabws#getdirectoryentryfortab(a:tabnum)
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

function! tabws#associatebufferwithtab(tab, buffer)
	if !buflisted(a:buffer) || !filereadable(bufname(a:buffer)) 
		return
	endif
	if !has_key(s:tabws_directory, a:tab)
		call tabws#createdirectoryentry(a:tab)
	endif
	let direntry = s:tabws_directory[a:tab]
	if index(direntry["buffers"], a:buffer) == -1
		call add(direntry["buffers"], a:buffer)
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
	return tablinestr
endfunction
function! tabws#refreshtabline()
	if get(g:, "airline#extensions#tabline#enabled", 0) == 0
		set tabline=%!TabWSGenerateTabline()
	endif
endfunction

function! tabws#fzftabssink(line)
    let pair = split(a:line, ' ')
    "call tabws#jumptobufferintab(tabws#getcurrentbuffer(pair[0]))
    call tabws#jumptotab(pair[0])
endfunction

function! tabws#fzftabs()
	call fzf#run({
\   'source':  reverse(map(range(1, tabpagenr('$')), 'v:val." "." ".tabws#gettabname(v:val)')),
\   'sink':    function('tabws#fzftabssink'),
\   'down':    tabpagenr('$') + 2
\ })
endfunction
