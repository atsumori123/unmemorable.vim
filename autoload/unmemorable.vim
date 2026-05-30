let s:save_cpo = &cpoptions
set cpoptions&vim

let s:W = {'win':0, 'buf':0}

" パスの省略数(Filepath to clipboard用)
let s:omit_num = 0

" 実行元のbufnr
let s:exec_bufnr = -1

" メニューツリー
" level:階層レベル, label:表示名, action:実行コマンド, child:子要素の有無
function! s:make_menu_tree() abort
	let s:menu_tree = [
		\	{'level': 0, 'label': 'Filepath to clipboard [omit='.s:omit_num.']', 'action': function('commands#filepath_to_clipboard', [s:omit_num]), 'edit': function('commands#edit_omit_num', [s:exec_bufnr])},
		\	{'level': 0, 'label': 'Auto Complete ['.(exists("#AutoComplete#InsertCharPre") ? 'ON' : 'OFF').']' , 'action' : function('commands#auto_complete')},
		\	{'level': 0, 'label': 'Buffer', 'child': 1},
		\		{'level': 1, 'label': 'Tab  ['.&tabstop.']', 'action': function('commands#tab')},
		\		{'level': 1, 'label': 'Modifiable  ['.(&modifiable ? "+" : "-").']', 'action': function('commands#modifiable')},
		\		{'level': 1, 'label': 'Read Only  ['.(&readonly ? 'RO' : 'RW').']', 'action': function('commands#rw')},
		\		{'level': 1, 'label': 'Visualization control code  ['.(&list ? 'ON' : 'OFF').']', 'action': function('commands#visualization')},
		\		{'level': 1, 'label': 'Ignore case  ['.(&ignorecase ? 'ON' : 'OFF').']', 'action': function('commands#ignorecase')},
		\		{'level': 1, 'label': 'OSC Yank ['.(exists("#OSCYank#TextYankPost") ? 'ON' : 'OFF').']', 'action': function('commands#osc_yank')},
		\	{'level': 0, 'label': 'Quickfix', 'child' : 1},
		\		{'level': 1, 'label': 'Reset error format', 'action': function('commands#reset_errorformat')},
		\		{'level': 1, 'label': 'Remove comment line', 'action': function('commands#remove_comment_line')},
		\	{'level': 0, 'label': 'Tab and Space', 'child' : 1},
		\		{'level': 1, 'label': 'Space to Tab', 'action': function('commands#space2tab', [s:range])},
		\		{'level': 1, 'label': 'Tab to Space', 'action': function('commands#tab2space', [s:range])},
		\		{'level': 1, 'label': 'Remove trailin Sapces and tabs from lines', 'action': function('commands#remove_space', [s:range])},
		\	{'level': 0, 'label': 'File Encord', 'child' : 1},
		\		{'level': 1, 'label': 'Reopen with specified encording', 'child' : 1},
		\			{'level': 2, 'label': 'utf-8', 'action': function('commands#reopen_encord', ['utf8'])},
		\			{'level': 2, 'label': 'sjis', 'action': function('commands#reopen_encord', ['sjis'])},
		\		{'level': 1, 'label': 'Convert with specified encording', 'child' : 1},
		\			{'level': 2, 'label': 'utf-8', 'action': function('commands#convert_encord', ['utf8'])},
		\			{'level': 2, 'label': 'sjis', 'action': function('commands#convert_encord', ['sjis'])},
		\	{'level': 0, 'label': 'NL-Code' , 'child' : 1},
		\		{'level': 1, 'label': 'Reopen with specified NL', 'child' : 1},
		\			{'level': 2, 'label': 'unix  [LF]', 'action': function('commands#reopen_nl', ['unix'])},
		\			{'level': 2, 'label': 'dos   [CR+LF]', 'action': function('commands#reopen_nl', ['dos'])},
		\			{'level': 2, 'label': 'mac   [CR]', 'action': function('commands#reopen_nl', ['mac'])},
		\		{'level': 1, 'label': 'Convert with specified NL', 'child' : 1},
		\			{'level': 2, 'label': 'unix  [LF]', 'action': function('commands#convert_nl', ['unix'])},
		\			{'level': 2, 'label': 'dos   [CR+LF]', 'action': function('commands#convert_nl', ['dos'])},
		\			{'level': 2, 'label': 'mac   [CR]', 'action': function('commands#convert_nl', ['mac'])}
		\ ]
endfunction

"-------------------------------------------------------
" 親のインデックス番号を取得する
"-------------------------------------------------------
function! s:search_parent(idx, level) abort
	" 今いる位置ががトップレベルの場合はそのまま返す
	if s:menu_tree[a:idx].level == 0
		return a:idx
	endif
	
	" 1つ上の要素から遡って親を探す
	let start = a:idx - 1
	for i in range(start, 0, -1)
		" levelが小さい(=親)要素か?
		if s:menu_tree[i].level < a:level
			return i
		endif
	endfor

	return 0
endfunction

"-------------------------------------------------------
" 表示用のメニューリストを作成する関数
"-------------------------------------------------------
function! s:make_menu()
	let lines = []
	let s:visible_map = [] " 表示行と元のデータインデックスの紐付け
  
	" メニューリストの数だけ繰り返す
	for i in range(0, len(s:menu_tree) - 1, 1)
		let item = s:menu_tree[i]
   
		" 表示/非表示 (トップレベルは必ず表示, 子要素は親の展開状況による
		if item.level == 0
			let should_show = 1
		else
			let should_show = !!get(s:expanded_indices, s:search_parent(i, item.level), 0)
		endif

		if should_show
        	" インデント計算（levelの大きさで計算）
			let prefix = repeat('  ', item.level)
			" 折り畳みマーク
			let mark = get(item, 'child', 0) ? (get(s:expanded_indices, i, 0) ? '- ' : '+ ') : '- '
			" 表示リストに追加
			call add(lines, ' ' . prefix . mark . item.label . ' ')
			" menu_tree[]の配列番号(0起算)を追加
			call add(s:visible_map, i)
		endif
	endfor

	return lines
endfunction

"-------------------------------------------------------
" 指定したインデックス配下の子要素をすべて再帰的に閉じる
"-------------------------------------------------------
function! s:collapse_recursive(parent_idx)
	" 親のレベル
	let parent_level = s:menu_tree[a:parent_idx].level
  
	" 次の要素から順に、親より深いレベルの要素を探す
	let i = a:parent_idx + 1
	while i < len(s:menu_tree) && s:menu_tree[i].level > parent_level
		if has_key(s:expanded_indices, i)
			let s:expanded_indices[i] = 0
		endif
		let i += 1
	endwhile
endfunction

"-------------------------------------------------------
" 再描画
"-------------------------------------------------------
function! s:redraw() abort
	" make menu
	let lines = s:make_menu()

	" 全消去
	setlocal modifiable
	silent %delete _

	" draw buffer
	silent! 0put = lines
	silent! $delete _
	normal! gg
	setlocal nomodifiable

	" 現在のウィンドウの元の設定を取得
	let config = nvim_win_get_config(0)

	" 高さを新しい高さに変更
	let height = len(lines)
	if height > &lines | let height = &lines - 4 | endif
	let config.height = height

	" 配列になってしまった borderを辞書から削除する
	if has_key(config, 'border')
		unlet config.border
	endif

	" 新しい設定をウィンドウに適用
	call nvim_win_set_config(0, config)
endfunction

"-------------------------------------------------------
" メニューの展開
"-------------------------------------------------------
function! s:expand_menu() abort
	let lnum = line('.')				" 行番号は1起算
	let idx = s:visible_map[lnum - 1]	" menu_tree[]の表示する要素の配列番号を管理 (0起算)
	let item = s:menu_tree[idx]

	if get(item, 'child', 0)
		" 子要素があるメニューの場合は展開フラグをオン
		let s:expanded_indices[idx] = 1

		" 再描画
		call s:redraw()

		" カーソル位置を設定
		call cursor(lnum + 1, 1)
	endif
endfunction

"-------------------------------------------------------
" メニューの折り畳み
"-------------------------------------------------------
function! s:fold_menu() abort
	let lnum = line('.')				" 行番号は1起算
	let idx = s:visible_map[lnum - 1]	" menu_tree[]の表示する要素の配列番号を管理 (0起算)
	let item = s:menu_tree[idx]

	" 遡って親を探し、再帰的に展開フラグをオフ
	let parent_idx = s:search_parent(idx, item.level)
	let s:expanded_indices[parent_idx] = 0

	" 再帰的に子要素の展開フラグをオフ
	call s:collapse_recursive(parent_idx)

	" 再描画
	call s:redraw()

	" カーソルを親のところに移動
	let n = len(filter(copy(s:visible_map), 'v:val <= idx'))
	call cursor(n, 1)
endfunction

"-------------------------------------------------------
" 選択
"-------------------------------------------------------
function! s:on_select()
	let lnum = line('.')				" 行番号は1起算
	let idx = s:visible_map[lnum - 1]	" menu_tree[]の表示する要素の配列番号を管理 (0起算)
	let item = s:menu_tree[idx]

	" actionが割りついていない場合は無視
	if !has_key(item, 'action') | return | endif

	call s:close_window()
	call item.action()
endfunction

"-------------------------------------------------------
" 編集
"-------------------------------------------------------
function! s:on_edit()
	let lnum = line('.')				" 行番号は1起算
	let idx = s:visible_map[lnum - 1]	" menu_tree[]の表示する要素の配列番号を管理 (0起算)
	let item = s:menu_tree[idx]

	" editが割りついていない場合は無視
	if !has_key(item, 'edit') | return | endif

	let ret = item.edit()
	if !empty(ret)
		execute ret
		call s:make_menu_tree()
		call s:redraw()

		" カーソルを元の位置に復元
		call cursor(lnum, 1)
	endif
endfunction

"-------------------------------------------------------
" 配列の全要素から最大の横幅を返す
"-------------------------------------------------------
function! s:max_width(lists) abort
	let max = 0
	for v in a:lists
		let max = max > len(v) ? max : len(v)
	endfor

	return max
endfunction

"-------------------------------------------------------
" ウィンドウの終了
"-------------------------------------------------------
function! s:close_window() abort
	if s:W.win && nvim_win_is_valid(s:W.win)
		call nvim_win_close(s:W.win, 1)
	endif

	let s:W.win = 0
	let s:W.buf = 0
endfunction

"-------------------------------------------------------
" set highlight
"-------------------------------------------------------
function! s:set_highlight() abort
	highlight link NormalFloat Normal
	highlight link FloatBorder Normal
endfunction

"-------------------------------------------------------
" ポップアップメニュー起動
"-------------------------------------------------------
function! s:open_popup()
	call s:close_window()

	" make menu
	let lines = s:make_menu()

	" create buffer
	let s:W.buf = nvim_create_buf(v:false, v:true)

	" create floating window
	let width = s:max_width(lines)
	if width > &columns - 4 | let width = &columns - 4 | endif
	let s:W.win = nvim_open_win(s:W.buf, v:true, {
						\ 'title'	: ' Unmemorable ',
						\ 'style'	: "minimal",
						\ 'relative': "editor",
						\ 'height'	: len(lines),
						\ 'width'	: width,
						\ 'col'		: ceil((&columns - width) * 0.5 - 1),
						\ 'row'		: ceil((&lines - len(lines)) * 0.5 - 1),
						\ 'border'	: "single",
						\ })

	" draw buffer
	silent! 0put = lines
	silent! $delete _
	normal! gg
	setlocal nomodifiable

	" set buffer option
	setlocal cursorline
	setlocal bufhidden=delete

	" フォーカスが外れたら自動で閉じる設定
	autocmd WinLeave <buffer> ++once if win_id2win(s:W.win) > 0 | call s:close_window() | endif

	" set highlight
	call s:set_highlight()

	" set keymaps
	nnoremap <buffer> <silent> <CR> :call <SID>on_select()<CR>
	nnoremap <buffer> <silent> e :call <SID>on_edit()<CR>
	nnoremap <buffer> <silent> q :call <SID>close_window()<CR>
	nnoremap <buffer> <silent> l :call <SID>expand_menu()<CR>
	nnoremap <buffer> <silent> h :call <SID>fold_menu()<CR>
endfunction

"-------------------------------------------------------
" Unmemorable start
"-------------------------------------------------------
function! unmemorable#start(range, start, end) abort
	" 選択範囲
	let s:range = {'range':a:range, 'start':a:start, 'end':a:end}

	" 状態管理：どのメニューが展開されているか (インデックスを保持)
	let s:expanded_indices = {}

	" 実行元のbufnr
	let s:exec_bufnr = bufnr("%")

	call s:make_menu_tree()
	call s:open_popup()
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo

