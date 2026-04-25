let s:save_cpo = &cpoptions
set cpoptions&vim

"-------------------------------------------------------
" OSC Yank
"-------------------------------------------------------
function! commands#osc_yank() abort
	if exists("#OSCYank#TextYankPost")
		augroup OSCYank
			autocmd!
		augroup END
	else
		augroup OSCYank
			autocmd!
			autocmd TextYankPost *
				\ if v:event.operator is 'y' && v:event.regname is '' |
				\ execute 'OSCYankRegister "' |
				\ endif
		augroup END
	endif
endfunction

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
	let bufs = filter(range(1, bufnr('$')), '
			\ buflisted(v:val)
			\ && getbufvar(v:val, "&buftype") == "quickfix"
			\ ')

	" Quickfixが開いてない場合は終了
	if !len(bufs) || bufwinnr(bufs[0]) <= 0
		echohl WarningMsg | echomsg 'Unopend quickfix' | echohl None
		return
	endif

	" Quickfixに移動
	exe bufwinnr(bufs[0]) . 'wincmd w'

	" コメント記号の開始部分を入力
	let cms = input('Comment string: ', '(//|/*)')
	if empty(cms) | return | endif

	" 記号をエスケープしてCfilter!を実行
	let pattern = escape(trim(cms), '*/\^$.[]()|')
	execute 'Cfilter! /^\s*' . pattern . '/'

	set modifiable
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo

