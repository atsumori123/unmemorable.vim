let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('g:loaded_unmemorable')
	finish
endif
let g:loaded_unmemorable = 1


command! -nargs=0 -range Unmemorable call unmemorable#start(<range>, <line1>, <line2>)

let &cpoptions = s:save_cpo
unlet s:save_cpo
