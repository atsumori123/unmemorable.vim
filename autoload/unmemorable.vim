let s:save_cpo = &cpoptions
set cpoptions&vim

let s:highlight_id = -1

function! s:make_menu_table() abort
	let s:MENU = [
		\	{'label': '- Filepath to clipboard. omit={%}', 'action': function('commands#filepath_to_clipboard'), 'param': function('commands#set_omit_num')},
		\	{'label': '- Auto Complete  ['.(exists("#AutoComplete#InsertCharPre") ? 'ON' : 'OFF').']' , 'action' : function('commands#auto_complete')},
		\	{'label': '- Tabstop  ['.&tabstop.']', 'action': function('commands#tab')},
		\	{'label': '- Modifiable. ['.(&modifiable ? "+" : "-").']', 'action': function('commands#modifiable')},
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
" 選択アイテムの行番号とメニューの要素番号の取得
"-------------------------------------------------------
function! s:get_lnum_and_id(winid) abort
	let lnum = line('.', a:winid)
	let s = substitute(trim(win_execute(a:winid, 'echo getline(".")')), '\[.*\]', '\\[.*\\]', '')
	let i = match(s:MENU, s)
	return [lnum, i]
endfunction

"-------------------------------------------------------
" パラメータの切り替え
"-------------------------------------------------------
function! s:change_param(winid, id, direction) abort
	" 選択アイテムの取得
	let item = s:MENU[a:id]

	" パラメータが存在しない場合は終了
	if type(get(item, "param", v:none)) == v:t_none | return | endif

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
endfunction

"-------------------------------------------------------
" Update popup menu
"-------------------------------------------------------
function! s:update_text(winid, old_pattern, pattern) abort
	let [old_len, new_len] = [len(a:old_pattern), len(a:pattern)]

	" フィルタリングパターンに変化が無い場合は処理なし
	if old_len == new_len | return | endif

	" フィルタパターンのハイライトをクリア(無効なID指定によるエラーは無視)
	silent! call matchdelete(s:highlight_id, a:winid)

	" ファイルリストを取得
	let files = copy(old_len < new_len ? getbufline(winbufnr(a:winid), 1, '$') : s:make_menu())

	" フィルタリングの条件式を作成
	if len(a:pattern)
		let cond = ""
		for v in split(a:pattern, "|")
			let cond .= printf("%sv:val %s '%s'", (len(cond) ? " && " : ""), (v =~# '[A-Z]' ? '=~#' : '=~?'), escape(v, '.'))
		endfor
		call filter(files, cond)
	endif

	" タイトルの更新
	call popup_setoptions(a:winid, {'title' : printf(" > %s ", a:pattern)})
	
	" 表示
	call popup_settext(a:winid, files)

	" フィルタリングパターンをハイライト
	if len(a:pattern)
		for v in split(a:pattern, "|")
			let s:highlight_id = matchadd('Title', (v =~# '[A-Z]' ? '' : '\c') . v, 10, -1, {'window': a:winid})
		endfor
	endif
endfunction

"-------------------------------------------------------
" 選択行を最新に更新
"-------------------------------------------------------
function! s:update_item(winid, lnum, id) abort
	" 現在の表示テキストを取得
	let lines = getbufline(winbufnr(a:winid), 1, '$')

	" 表示テキストに反映
	let lines[a:lnum - 1] = s:MENU[a:id].label

	" 表示
	call popup_settext(a:winid, lines)
endfunction

"-------------------------------------------------------
" ポップアップのフィルタ（キー入力制御）
"-------------------------------------------------------
function! s:menu_filter(winid, key)
	let old_pattern = s:pattern

	if a:key ==# "\<BS>" || a:key =~ '^[a-z0-9_._\|\ ]\+$'
		let s:pattern = a:key ==# "\<BS>" ? s:pattern[:-2] : s:pattern . a:key
		call s:update_text(a:winid, old_pattern, s:pattern)
		return 1

	elseif a:key ==# "\<c-j>"
		call win_execute(a:winid, 'normal! j')
		return 1

	elseif a:key ==# "\<c-k>"
		call win_execute(a:winid, 'normal! k')
		return 1

	elseif a:key ==# "\<c-f>"
		call win_execute(a:winid, 'normal! 18j')
		return 1

	elseif a:key ==# "\<c-b>"
		call win_execute(a:winid, 'normal! 18k')
		return 1

	elseif a:key ==# "\<c-u>"
		let s:pattern = ""
		call s:update_text(a:winid, "dummy", s:pattern)
		return 1

	elseif a:key ==# "\<c-l>" || a:key ==# "\<c-h>"
		let [lnum, id] = s:get_lnum_and_id(a:winid)
		call s:change_param(a:winid, id, a:key ==# "\<c-l>" ? 1 : -1)
		call s:update_item(a:winid, lnum, id)
		return 1

	elseif a:key ==# "\<ESC>"
		call popup_close(a:winid, -1)
		return -1
	endif

	return popup_filter_menu(a:winid, a:key)
endfunction

"---------------------------------------------------------------
" Selected handler
"---------------------------------------------------------------
function! s:on_select(winid, result) abort
	" <ESC>の場合は終了
	if a:result == -1 | return | endif

	" 選択アイテムの取得
	let [lnum, id] = s:get_lnum_and_id(a:winid)
	let item = s:MENU[id]

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
" ポップアップメニュー起動
"-------------------------------------------------------
function! s:open_popup()
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
			\ 'callback':		function('s:on_select'),
			\ 'filter':			function('s:menu_filter'),
			\ }

	const winid = popup_menu(s:make_menu(), opts)

	" []の部分をハイライト
	call matchadd('Identifier', '\[[^\]]*\]', 10, -1, {'window': winid})
	" {}の部分をハイライト
	call matchadd('Question', '{[^}]*}', 10, -1, {'window': winid})
endfunction

"-------------------------------------------------------
" Unmemorable start
"-------------------------------------------------------
function! unmemorable#start(range, start, end) abort
	let s:pattern = ""
	let s:highlight_id = -1

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

