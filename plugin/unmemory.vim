let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('g:loaded_unmemory')
	finish
endif
let g:loaded_unmemory = 1


command! -nargs=0 -range Unmemory call unmemory#start(<range>, <line1>, <line2>)

let &cpoptions = s:save_cpo
unlet s:save_cpo
