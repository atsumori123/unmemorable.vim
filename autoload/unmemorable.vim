let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:init_menutree() abort
	let s:menu_tree = {
		\ 'Unmemorable' : { 'id' : 100, 'menu' : [
		\		' - Filepath to clipboard',
		\		' + Buffer',
		\		' + Quickfix',
		\		' + Tab and Space',
		\	 	' + File Encord',
		\	 	' + NL-Code',
		\	 	' - CD ['.getcwd().']'
		\ ]},
		\ 'Buffer' : { 'id' : 200, 'menu' : [
		\		' - Tab  ['.&tabstop.']',
		\		' - Modifiable  ['.(&modifiable ? "+" : "-").']',
		\		' - Read Only  ['.(&readonly ? 'RO' : 'RW').']',
		\		' - Visualization control code  ['.(&list ? 'ON' : 'OFF').']',
		\		' - Ignore case  ['.(&ignorecase ? 'ON' : 'OFF').']'
		\ ]},
		\ 'Quickfix' : { 'id' : 300, 'menu' : [ 
		\		' - Reset error format',
		\		' - Remove comment line'
		\ ]},
		\ 'Tab and Space' : { 'id' : 400, 'menu' : [ 
		\		' - Space to Tab',
		\		' - Tab to Space',
		\		' - Remove Sapce/Tab end of line'
		\ ]},
		\ 'File Encord' : { 'id' : 500, 'menu' : [
		\		' > Reopen with specified encording',
		\		'   - utf-8',
		\		'   - sjis',
		\		' > Convert with specified encording',
		\		'   - utf-8',
		\		'   - sjis'
		\ ]},
		\ 'NL-Code' : { 'id' : 600, 'menu' : [
		\		' > Reopen with specified NL',
		\		'   - unix  [\n]',
		\		'   - dos   [\r\n]',
		\		'   - mac   [\r]',
		\		' > Convert with specified NL',
		\		'   - unix  [\n]',
		\		'   - dos   [\r\n]',
		\		'   - mac   [\r]'
		\ ]}
	\}

	let s:menu = []
	let s:menu_name = ""
	let s:menu_stack = []
endfunction

"-------------------------------------------------------
" Create popup menu
"-------------------------------------------------------
function! s:open_popup(name) abort
	let s:menu = get(s:menu_tree, a:name, []).menu

	let opts = {
			\ 'border': [1,1,1,1],
			\ 'padding': [1,2,1,2],
			\ 'minwidth':50,
			\ 'mapping': v:false,
			\ 'title': ' [ Unmemorable ] ',
			\ 'callback': function('s:menu_handler'),
			\ 'filter': function('s:menu_filter')
			\ }

	const winid = popup_menu(s:menu, opts)
	let s:menu_name = a:name
endfunction

"-------------------------------------------------------
" Update popup menu
"-------------------------------------------------------
function! s:update_popup(winid, name) abort
	let s:menu = get(s:menu_tree, a:name, []).menu
	let s:menu_name = a:name
	call popup_settext(a:winid, s:menu)
	let title = " [ " . join(map(copy(s:menu_stack), 'v:val . " / "'), "") . a:name . " ] "
	call popup_setoptions(a:winid, {'title' : title})
    call win_execute(a:winid, 'normal! gg')
endfunction

"-------------------------------------------------------
" menu filter
"-------------------------------------------------------
function! s:menu_filter(winid, key) abort
    if a:key ==# 'q'
        call popup_close(a:winid, -1)
        return 1
    endif

	" 現在の選択行と全行数を取得
	let l:cur_line = getcurpos(a:winid)[1]
	let l:last_line = line('$', a:winid)

	if a:key ==# 'j' || a:key ==# "\<Down>"
		" 一番下なら一番上へ、そうでなければ次へ
		let l:target = (l:cur_line >= l:last_line) ? 1 : l:cur_line + 1
		call win_execute(a:winid, 'normal! ' . l:target . 'G')
		return 1

	elseif a:key ==# 'k' || a:key ==# "\<Up>"
		" 一番上なら一番下へ、そうでなければ前へ
		let l:target = (l:cur_line <= 1) ? l:last_line : l:cur_line - 1
		call win_execute(a:winid, 'normal! ' . l:target . 'G')
		return 1

	elseif a:key ==# "\<CR>" || a:key ==# 'l'
		" 選択行の取得 (先頭3文字は除去)
		let item = s:menu[cur_line - 1]
		let kind = matchstr(item, '\S')
		let name = item[3:]
		if kind ==# '+' && has_key(s:menu_tree, name)
			" 子メニューの表示
			call add(s:menu_stack, s:menu_name)
			call s:update_popup(a:winid, name)
			return 1
		elseif kind ==# '-'
			" コマンドの実行
			call popup_close(a:winid, s:menu_tree[s:menu_name].id + cur_line)
			return 1
		endif

	elseif a:key ==# 'h' && !empty(s:menu_stack)
		let name = remove(s:menu_stack, -1)
		call s:update_popup(a:winid, name)
		return 1

	endif

	return popup_filter_menu(a:winid, a:key)
endfunction

"-------------------------------------------------------
" Selected handler
"-------------------------------------------------------
function! s:menu_handler(winid, result) abort

	if	   a:result == 101	" Filepath to clipboard
		let @* = expand("%:p")
		echohl MoreMsg | echomsg "Set file path to clipboard (".@*.")" | echohl None

	elseif a:result == 107	" CD (chage current directory)
		let dir = input('Set current directory: ', expand("%:h"), 'dir')
		if !empty(dir)
			execute 'lcd '.dir
			echohl MoreMsg | echomsg "Change to '".getcwd()."'" | echohl None
		endif

	elseif a:result == 201	" Tab 4/8
		let tab = &tabstop == 4 ? 8 : 4
		execute 'set tabstop='.tab
		execute 'set shiftwidth='.tab

	elseif a:result == 202	" Modifiable
		execute &modifiable ? 'set nomodifiable' : 'set modifiable'

	elseif a:result == 203	" Read Only
		execute &readonly ? 'set noro' : 'set ro'

	elseif a:result == 204	" Visualization control code
		execute &list ? 'set nolist' : 'set list'

	elseif a:result == 205	" Ignore case
		execute &ignorecase ? 'set noignorecase' : 'set ignorecase'

	elseif a:result == 301	" Reset error format
		call commands#reset_errorformat()

	elseif a:result == 302	" Remove comment line
		call commands#remove_comment_line()

	elseif a:result == 401	" Tab and Space / Space to Tab
		call commands#space2tab(s:range)

	elseif a:result == 402	" Tab and Space / Tab to Space
		call commands#tab2space(s:range)

	elseif a:result == 403	" Tab and Space / Remove Sapce/Tab end of line
		call commands#remove_space(s:range)

	elseif a:result == 502	" File Encord / Reopen with utf-8 encording
		execute 'e ++enc=utf8'

	elseif a:result == 503	" File Encord / Reopen with sjis encording
		execute 'e ++enc=sjis'

	elseif a:result == 505	" File Encord / Convert to utf-8 encording
		execute 'set fenc=utf8'

	elseif a:result == 506	" File Encord / Convert to sjis encording
		execute 'set fenc=sjis'

	elseif a:result == 602	" NL-Code  / Reopen with unix NL
		execute 'edit ++fileformat=unix'

	elseif a:result == 603	" NL-Code  / Reopen with unix dos
		execute 'edit ++fileformat=dos'

	elseif a:result == 604	" NL-Code  / Reopen with unix mac
		execute 'edit ++fileformat=mac'

	elseif a:result == 606	" NL-Code  / Convert to unix NL
		execute 'set fileformat=unix'

	elseif a:result == 607	" NL-Code  / Convert to unix dos
		execute 'set fileformat=dos'

	elseif a:result == 608	" NL-Code  / Convert to unix mac
		execute 'set fileformat=mac'

	endif
endfunction

"-------------------------------------------------------
" Unmemorable start
"-------------------------------------------------------
function! unmemorable#start(range, start, end) abort
	let s:menu_stack = []
	let s:range = {'range':a:range, 'start':a:start, 'end':a:end}
	call s:init_menutree()
	call s:open_popup('Unmemorable')
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo

