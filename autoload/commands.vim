let s:save_cpo = &cpoptions
set cpoptions&vim

"-------------------------------------------------------
" Space to Tab
"-------------------------------------------------------
function! commands#space2tab(range) abort
	let s = substitute(execute("set expandtab?"), '[ \|\n]', "", "ge")
	execute ':set noexpandtab'
	if a:range['range']
		execute ':'.a:range['start'].','.a:range['end'].'retab!'
	else
		execute ':retab!'
	endif
	execute ':set '.s
endfunction

"-------------------------------------------------------
" Tab to Space
"-------------------------------------------------------
function! commands#tab2space(range) abort
	let s = substitute(execute("set expandtab?"), '[ \|\n]', "", "ge")
	execute ':set expandtab'
	if a:range['range']
		execute ':'.a:range['start'].','.a:range['end'].'retab'
	else
		execute ':retab'
	endif
	execute ':set '.s
endfunction

"-------------------------------------------------------
" Remove Spaces and Tabs at end of lines
"-------------------------------------------------------
function! commands#remove_space(range) abort
	let pos = getpos(".")
	if a:range['range']
		silent execute ':'.a:range['start'].','.a:range['end'].'s/\s\+$//eg'
	else
		silent execute ':%s/\s\+$//e'
	endif
	call setpos('.', pos)
endfunction

"-------------------------------------------------------
" Reset error format
"-------------------------------------------------------
function! commands#reset_errorformat() abort
	let bufs = filter(range(1, bufnr('$')), '
			\ buflisted(v:val)
			\ && getbufvar(v:val, "&buftype") == "quickfix"
			\ ')

	if len(bufs) && bufwinnr(bufs[0]) > 0
		exe bufwinnr(bufs[0]) . 'wincmd w'
		if !exists('g:GR_GrepCommand') || g:GR_GrepCommand == "internal"
			execute 'set errorformat=%f\|%l\ col\ \%c-\%k\|\ %m'
		else
			execute 'set errorformat=%f\|%l\|\ %m'
		endif
		silent cgetbuffer
		set modifiable
	else
		echohl WarningMsg | echomsg 'This buffer type is not quickfix' | echohl None
		return
	endif
endfunction

"-------------------------------------------------------
" Remove comment line
"-------------------------------------------------------
function! commands#remove_comment_line() abort
	execute 'Cfilter! /\/\/\(.*\)\|\/\*\(.*\)\*\//'
	set modifiable
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo

