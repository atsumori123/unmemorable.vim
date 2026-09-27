if exists('g:loaded_unmemorable')
	finish
endif
let g:loaded_unmemorable = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

command! -nargs=0 -range Unmemorable call unmemorable#start(<range>, <line1>, <line2>)

if get(g:, 'unmemorable_auto_complete_enable', 0)
	call commands#auto_complete()
endif

if get(g:, 'unmemorable_osc52yank', 0)
	call commands#osc52yank(get(["OFF", "ON", "ON(cp932)"], g:unmemorable_osc52yank, "OFF"))
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
