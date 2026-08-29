if exists('g:loaded_unmemorable')
	finish
endif
let g:loaded_unmemorable = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

command! -nargs=0 -range Unmemorable call unmemorable#start(<range>, <line1>, <line2>)

if exists('g:unmemorable_auto_complete_enable') && g:unmemorable_auto_complete_enable
	call commands#auto_complete()
endif

if exists('g:unmemorable_osc_yank_enable') && g:unmemorable_osc_yank_enable
	call commands#osc_yank()
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
