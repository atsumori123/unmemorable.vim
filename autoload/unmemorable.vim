let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:make_menu_table() abort
	let s:MENU = [
		\	{'label': '- Filepath to clipboard. omit={%}', 'action': function('commands#filepath_to_clipboard'), 'param': function('commands#set_omit_num')},
		\	{'label': '- Auto Complete  ['.(exists("#AutoComplete#InsertCharPre") ? 'ON' : 'OFF').']' , 'action' : function('commands#auto_complete')},
		\	{'label': '- Tabstop  ['.&tabstop.']', 'action': function('commands#tab')},
		\	{'label': '- Modifiable  ['.(&modifiable ? "+" : "-").']', 'action': function('commands#modifiable')},
		\	{'label': '- Read Only  ['.(&readonly ? 'RO' : 'RW').']', 'action': function('commands#rw')},
		\	{'label': '- Ignore case  ['.(&ignorecase ? 'ON' : 'OFF').']', 'action': function('commands#ignorecase')},
		\	{'label': '- Visualization control code  ['.(&list ? 'ON' : 'OFF').']', 'action': function('commands#visualization')},
		\	{'label': '- OSC Yank  ['.(exists("#OSCYank#TextYankPost") ? 'ON' : 'OFF').']', 'action': function('commands#osc_yank')},
		\	{'label': '- Reset error format (Quickfix)', 'action': function('commands#reset_errorformat')},
		\	{'label': '- Remove comment line (Quickfix)', 'action': function('commands#remove_comment_line')},
		\	{'label': '- Space to Tab', 'action': function('commands#space2tab'), 'arg':'range'},
		\	{'label': '- Tab to Space', 'action': function('commands#tab2space'), 'arg':'range'},
		\	{'label': '- Remove trailin Sapces and tabs from lines', 'action': function('commands#remove_space'), 'arg':'range'},
		\	{'label': '- Reopen with {%} encording  (utf8/sjis)', 'action': function('commands#reopen_encord'), 'param':['utf8', 'sjis']},
		\	{'label': '- Convert to {%} encording  (utf8/sjis)', 'action': function('commands#convert_encord'), 'param':['utf8', 'sjis']},
		\	{'label': '- Reopen with {%} style NL code  (unix:LF/dos:CR+LF/mac:CR)', 'action': function('commands#reopen_nl'), 'param':["unix", "dos", "mac"]},
		\	{'label': '- Convert to {%} style NL code  (unix:LF/dos:CR+LF/mac:CR)', 'action': function('commands#convert_nl'), 'param':["unix", "dos", "mac"]}
		\ ]
endfunction

"-------------------------------------------------------
" 表示用のメニューリストを作成
"-------------------------------------------------------
function! s:make_menu()
	" メニューの数だけ繰り返す
	let lines = []
	for item in s:MENU
		if has_key(item, 'param')
			let v = type(item.param) == v:t_func ? item.param(0) : type(item.param) == v:t_list ? item.param[0] : item.param
			let item.label = substitute(item.label, '{\zs[^}]*\ze}', v, '')
		endif
  		call add(lines, item.label) 
	endfor

	return lines
endfunction

"-------------------------------------------------------
" 選択アイテムの要素番号を返却する
"-------------------------------------------------------
function! s:get_item_no(win) abort
	let s = substitute(trim(win_execute(a:win, 'echo getline(".")')), '\[.*\]', '\\[.*\\]', '')
	return match(s:MENU, s)
endfunction

"-------------------------------------------------------
" パラメータの切り替え
"-------------------------------------------------------
function! s:change_param(win, direction) abort
	" カーソル位置の行番号(1起算)を返却する
	let lnum = win_execute(a:win, 'echo line(".")') ->trim() ->str2nr()

	" 選択アイテムの取得
	let item = s:MENU[s:get_item_no(a:win)]

	" パラメータが存在しない場合は終了
	if has("nvim")
		if type(get(item, "param", v:null)) == type(v:null) | return | endif
	else
		if type(get(item, "param", v:none)) == v:t_none | return | endif
	endif

	" 値の更新
	if type(item.param) == v:t_func		" 関数
		let val = item.param(a:direction)

	elseif type(item.param) == v:t_list	" リスト
		" パラメータが選択項目の場合
		if a:direction > 1	" 次の要素
			call add(item.param, remove(item.param, 0))
		else				" 前の要素
			call insert(item.param, remove(item.param, -1), 0)
		endif
		let val = item.param[0]
	else								" 数値
		let item.param = max([item.param + a:direction, 0])
		let val = item.param
	endif

	" 新しいパラメータに更新
	let item.label = substitute(item.label, '{\zs[^}]*\ze}', val, '')

	" 表示を更新
	call setbufline(winbufnr(a:win), lnum, item.label)
endfunction

"-------------------------------------------------------
" Update popup menu
"-------------------------------------------------------
function! s:update_text(win, new_pattern) abort
	" フィルタパターンのハイライトをクリア(無効なID指定によるエラーは無視)
	silent! call matchdelete(s:highlight_id, a:win)

	" ファイルリストを取得
	let f = (len(s:old_pattern) <= len(a:new_pattern)) && stridx(a:new_pattern, s:old_pattern, 0) == 0 ? 1 : 0
	let files = copy(f ? getbufline(winbufnr(a:win), 1, '$') : s:make_menu())

	" フィルタリングの条件式を作成
	if len(a:new_pattern)
		let cond = ""
		for v in split(a:new_pattern, "|")
			let cond .= printf("%sv:val %s '%s'", (len(cond) ? " && " : ""), (v =~# '[A-Z]' ? '=~#' : '=~?'), escape(v, '.'))
		endfor
		call filter(files, cond)
	endif

	" タイトルとメニューを更新
	if has("nvim")
		call nvim_win_set_config(a:win, {'title' : printf(" > %s ", a:new_pattern)})
		call nvim_buf_set_text(0, 0, 0, -1, -1, files)
		call nvim_win_set_cursor(0, [1, 0])
	else
		call popup_setoptions(a:win, {'title' : printf(" > %s ", a:new_pattern)})
		call popup_settext(a:win, files)
		call win_execute(a:win, 'call cursor(1, 1)')
	endif

	" フィルタリングパターンをハイライト
	if len(a:new_pattern)
		for v in split(a:new_pattern, "|")
			let s:highlight_id = matchadd('Title', (v =~# '[A-Z]' ? '' : '\c') . v, 10, -1, {'window': a:win})
		endfor
	endif

	" フィルタリングパターンを記憶
	let s:old_pattern = a:new_pattern
endfunction

"---------------------------------------------------------------
" debounce update
"---------------------------------------------------------------
function! s:debounce_update(winid, key)
	if a:key == "BS"
		let s:pattern = s:pattern[:-2]
	elseif a:key == "CLR"
		let s:pattern = ""
	else
		let s:pattern .= a:key
	endif
		
	" タイマーが動いていたら停止
	if s:timer_id != 0 | call timer_stop(s:timer_id) | endif
	" 150ms 入力が止まったら実行
	let s:timer_id = timer_start(150, {-> s:update_text(a:winid, s:pattern)})
endfunction

"---------------------------------------------------------------
" 選択アイテムの実行
"---------------------------------------------------------------
function! s:on_select(win, no) abort
	" 選択アイテムを取得
	let item = s:MENU[a:no]

	if has("nvim")
		call nvim_win_close(0, 1)
	else
		call popup_close(a:win, 1)
	endif

	" コマンドの実行
	if has_key(item, 'param')
		if type(item.param) == v:t_func
			call item.action()
		elseif type(item.param) == v:t_list
			call item.action(item.param[0])
		else
			call item.action(item.param)
		endif
	else
		call item.action()
	endif

	unlet s:MENU
endfunction

"-------------------------------------------------------
" ポップアップのフィルタ（キー入力制御）
"-------------------------------------------------------
function! s:menu_filter(win, key)
	if a:key =~ '^[a-z0-9_._\|\ ]\+$'
		call s:debounce_update(a:win, a:key)
		return 1

	elseif a:key == "\<BS>"
		call s:debounce_update(a:win, "BS")
		return 1

	elseif a:key == "\<c-j>"
		return popup_filter_menu(a:win, 'j')

	elseif a:key == "\<c-k>"
		return popup_filter_menu(a:win, 'k')

	elseif a:key == "\<c-f>"
		call win_execute(a:win, 'normal! 18j')
		return 1

	elseif a:key == "\<c-b>"
		call win_execute(a:win, 'normal! 18k')
		return 1

	elseif a:key == "\<c-u>"
		call s:debounce_update(a:win, "CLR")
		return 1

	elseif a:key == "\<c-l>"
		call s:change_param(a:win, 1)
		return 1

	elseif a:key == "\<c-h>"
		call s:change_param(a:win, -1)
		return 1

	elseif a:key == "\<CR>"
		call s:on_select(a:win, s:get_item_no(a:win))
		return 1
	endif

	return popup_filter_menu(a:win, a:key)
endfunction

if has('nvim')
"-------------------------------------------------------
" ポップアップメニュー起動
"-------------------------------------------------------
function! s:open_popup() abort
	" バッファを作成 (listed=false, scratch(使い捨て)=true)
	let buf = nvim_create_buf(v:false, v:true)

	" create floating window
	let win = nvim_open_win(buf, v:true, {
						\ "title"	: " > ",
						\ "style"	: "minimal",
						\ "relative": "editor",
						\ "height"	: len(s:MENU),
						\ "width"	: 80,
						\ "col"		: float2nr((&columns - 80) * 0.5 - 1),
						\ "row"		: float2nr((&lines - len(s:MENU)) * 0.5 -1),
						\ "border"	: "rounded",
						\ })

	" 変更禁止解除→描画
	setlocal modifiable
	call nvim_buf_set_lines(0, 0, -1, v:false, s:make_menu())

	" カーソルを先頭に設定
	call nvim_win_set_cursor(0, [1, 0])

	" set buffer option
	setlocal bufhidden=wipe
	setlocal noswapfile
	setlocal nowrap
	setlocal cursorline

	" フォーカスが外れたら自動で閉じる(winid=0(現在のウィンドウ), force=1)
	autocmd WinLeave <buffer> ++once call nvim_win_close(0, 1)

	" []の部分をハイライト
	call matchadd('Identifier', '\[[^\]]*\]', 10, -1, {'window': win})
	" {}の部分をハイライト
	call matchadd('Special', '{[^}]*}', 10, -1, {'window': win})

	" 必要な文字を一括登録
	let keys = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.|"
	for i in range(0, len(keys) - 1)
		let k = escape(keys[i], '|')
		execute printf('nnoremap <buffer> <silent> %s :call <SID>debounce_update(%d, "%s")<CR>', k, win, k)
	endfor

	nnoremap <buffer> <silent> <c-j> j
	nnoremap <buffer> <silent> <c-k> k
	execute printf("nnoremap <buffer> <silent> <nowait> <ESC> :call nvim_win_close(0, v:true)<CR>")
	execute printf('nnoremap <buffer> <silent> <CR>  :call <SID>on_select(0, <SID>get_item_no(%d))<CR>', win)
	execute printf('nnoremap <buffer> <silent> <BS>  :call <SID>debounce_update(%d, "BS")<CR>', win)
	execute printf('nnoremap <buffer> <silent> <c-u> :call <SID>debounce_update(%d, "CLR")<CR>', win)
	execute printf('nnoremap <buffer> <silent> <c-l> :call <SID>change_param(%d, 1)<CR>', win)
	execute printf('nnoremap <buffer> <silent> <c-h> :call <SID>change_param(%d, -1)<CR>', win)
endfunction

else
"-------------------------------------------------------
" ポップアップメニュー起動
"-------------------------------------------------------
function! s:open_popup() abort
	let opts = {
        	\ 'title':			' > ',
			\ 'border':			[1,1,1,1],
			\ 'padding':		[1,2,1,2],
			\ 'borderchars':	has('unix') ? [] : ['─','│','─','│','┌','┐','┘','└'],
			\ 'minheight':		len(s:MENU),
			\ 'maxheight':		len(s:MENU),
			\ 'minwidth':		80,
			\ 'mmaxwidth':		80,
			\ 'mapping':		v:false,
			\ 'wrap':			v:false,
			\ 'scrollbar':		0,
			\ 'filter':			function('s:menu_filter'),
			\ }

	const win = popup_menu(s:make_menu(), opts)

	" []の部分をハイライト
	call matchadd('Identifier', '\[[^\]]*\]', 10, -1, {'window': win})
	" {}の部分をハイライト
	call matchadd('Question', '{[^}]*}', 10, -1, {'window': win})
endfunction
endif

"-------------------------------------------------------
" Unmemorable start
"-------------------------------------------------------
function! unmemorable#start(range, start, end) abort
	let s:pattern = ""
	let s:old_pattern = ""
	let s:highlight_id = -1
	let s:timer_id = 0

	" 初期設定
	let conf = {
			\ 'exec_bufnr': bufnr("%"),
			\ 'range': {'valid':a:range, 'start':a:start, 'end':a:end},
			\ }
	call commands#init(conf)

	call s:make_menu_table()

	call s:open_popup()
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo

