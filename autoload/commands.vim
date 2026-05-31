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

"-------------------------------------------------------
" ファイルパスをクリップボードに設定
"-------------------------------------------------------
function! commands#filepath_to_clipboard(omit_num) abort
	let separator = has('unix') ? '/' : '\\'
	let parts = split(expand("%:p"), separator)
	let @* = join(parts[a:omit_num:], separator)
	echohl MoreMsg | echomsg '[To clipboard] '.@* | echohl None
endfunction

"-------------------------------------------------------
" ファイルパスの省略数設定
"-------------------------------------------------------
function! commands#edit_omit_num() abort
	let val = input('omit num : ')
	if val !~# '^\d\+$' | let val = 0 | endif

	let separator = has('unix') ? '/' : '\\'
	let parts = split(expand("%:p"), separator)
	let path = join(parts[val:], separator)

	echohl MoreMsg | echomsg '[omit:' . val . '] '. path | echohl None
	return 'let s:omit_num = ' . val
endfunction

"-------------------------------------------------------
" タブ幅 4 / 8
"-------------------------------------------------------
function! commands#tab() abort
	let tab = &tabstop == 4 ? 8 : 4
	execute 'set tabstop='.tab
	execute 'set shiftwidth='.tab
endfunction

"-------------------------------------------------------
" 編集可 / 否
"-------------------------------------------------------
function! commands#modifiable() abort
	execute &modifiable ? 'set nomodifiable' : 'set modifiable'
endfunction

"-------------------------------------------------------
" Writable / Read Only
"-------------------------------------------------------
function! commands#rw() abort
	execute &readonly ? 'set noro' : 'set ro'
endfunction

"-------------------------------------------------------
" 空白/タブの表示 / 非表示
"-------------------------------------------------------
function! commands#visualization() abort
	execute &list ? 'set nolist' : 'set list'
endfunction

"-------------------------------------------------------
" 大文字 / 小文字の区別
"-------------------------------------------------------
function! commands#ignorecase() abort
	execute &ignorecase ? 'set noignorecase' : 'set ignorecase'
endfunction

"-------------------------------------------------------
" 指定のエンコードしてファイルを再オープン
"-------------------------------------------------------
function! commands#reopen_encord(type) abort
	execute 'e ++enc=' . a:type
endfunction

"-------------------------------------------------------
" 指定のエンコードに変換
"-------------------------------------------------------
function! commands#convert_encord(type) abort
	execute 'set fenc=' . a:type
endfunction

"-------------------------------------------------------
" 指定の改行コードでファイルを再オープン
"-------------------------------------------------------
function! commands#reopen_nl(type) abort
	execute 'edit ++fileformat=' . a:type
endfunction

"-------------------------------------------------------
" 指定の改行コードに変換
"-------------------------------------------------------
function! commands#convert_nl(type) abort
	execute 'set fileformat=' . a:type
endfunction

"-------------------------------------------------------
" Auto Complete
"
" Reference plugins
"
" Vimの手動補完を自動でトリガーすれば自動補完になります
" https://zenn.dev/kawarimidoll/articles/c14c8bc0d7d73d
"
" Vim scriptで関数のdebounceとthrottle
" https://zenn.dev/vim_jp/articles/9b1db46217a27d
"-------------------------------------------------------
function! commands#auto_complete() abort
	if exists("#AutoComplete#InsertCharPre")
		augroup AutoComplete
			autocmd!
		augroup END
	else
		" 補完動作の設定
		" auto_cmp_startが何度も呼ばれないようにmenuoneでpumを表示
		" 自動で選択までされないようnoselect
		set completeopt=menuone,noselect

		augroup AutoComplete
			autocmd!
			autocmd InsertCharPre * call s:debounce(function('s:auto_cmp_start'), 0)
			autocmd TextChangedP * call s:auto_cmp_close()
		augroup END
	endif
endfunction

let s:MINIMUM_COMPLETE_LENGTH = 3
"-------------------------------------------------------
" 補完の開始
"-------------------------------------------------------
function! s:auto_cmp_start(timer) abort
  " 既に補完ウィンドウが表示されている場合は何もせず終了
	if pumvisible() | return | endif

	" カーソルより左側の範囲を取得し、[:keyword:]を使って補完に使えない記号などを除去
"	let prev_str = (slice(getline('.'), 0, charcol('.')-1) .. v:char) ->substitute('.*[^[:keyword:]]', '', '')
"	let prev_str = (strpart(getline('.'), 0, charcol('.')-1) .. v:char) ->substitute('.*[^[:keyword:]]', '', '')
	" 日本語などのマルチバイト文字にも対応
	let prev_str = (strcharpart(getline('.'), 0, charcol('.')-1) .. v:char) ->substitute('.*[^[:keyword:]]', '', '')

	" カーソル直前の部分（補完元文字列）が最低文字数に満たなければ終了
	if strchars(prev_str) < s:MINIMUM_COMPLETE_LENGTH
		return
	endif

	" <c-n>を実行して補完スタート
	call feedkeys("\<c-n>", 'ni')
endfunction

"-------------------------------------------------------
" 補完の終了
"-------------------------------------------------------
function! s:auto_cmp_close() abort
	" ファイルパス補完の場合は区切り文字が違うので無視
	if complete_info(['mode']).mode == "files" | return | endif

	" カーソル直前の部分（補完元文字列）の文字列を調査
"	let prev_str = slice(getline('.'), 0, charcol('.')-1) ->substitute('.*[^[:keyword:]]', '', '')
	" 日本語などのマルチバイト文字にも対応
	let prev_str = strcharpart(getline('.'), 0, charcol('.')-1) ->substitute('.*[^[:keyword:]]', '', '')

	" 最低文字数に満たなければ`<c-x><c-z>`で補完を終了する
	if strchars(prev_str) < s:MINIMUM_COMPLETE_LENGTH
		call feedkeys("\<c-x>\<c-z>", 'ni')
	endif
endfunction

"-------------------------------------------------------
" debounce
"-------------------------------------------------------
let s:debounce_timers = {}
function s:debounce(fn, wait) abort
	let timer_name = string(a:fn)
	call get(s:debounce_timers, timer_name, 0)->timer_stop()
	let s:debounce_timers[timer_name] = timer_start(a:wait, a:fn)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo

