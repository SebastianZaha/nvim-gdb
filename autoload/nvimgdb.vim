
function! nvimgdb#ClearAugroup(name)
  exe "augroup " . a:name
    au!
  augroup END
  exe "augroup! " . a:name
endfunction


function! s:GetExpression(...) range
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][:col2 - 1]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfunction


"Shared global state initialization (commands, keymaps etc)
function! nvimgdb#GlobalInit()
  command! GdbDebugStop lua NvimGdb.cleanup(vim.api.nvim_get_current_tabpage())
  command! GdbBreakpointToggle lua NvimGdb.here:breakpoint_toggle()
  command! GdbBreakpointClearAll lua NvimGdb.here:breakpoint_clear_all()
  command! GdbFrame lua NvimGdb.here:send('f')
  command! GdbRun lua NvimGdb.here:send('run')
  command! GdbUntil lua NvimGdb.here:send('until %s', vim.fn.line('.'))
  command! GdbContinue lua NvimGdb.here:send('c')
  command! GdbNext lua NvimGdb.here:send('n')
  command! GdbStep lua NvimGdb.here:send('s')
  command! GdbFinish lua NvimGdb.here:send('finish')
  command! GdbFrameUp lua NvimGdb.here:send('up')
  command! GdbFrameDown lua NvimGdb.here:send('down')
  command! GdbInterrupt lua NvimGdb.here:send()
  command! GdbEvalWord lua NvimGdb.here:send('print %s', vim.fn.expand('<cword>'))
  command! -range GdbEvalRange call luaeval("NvimGdb.here:send('print %s', _A[1])", [s:GetExpression(<f-args>)])
  command! -nargs=1 GdbCreateWatch call luaeval("NvimGdb.here:create_watch(_A[1], '<mods>')", [<q-args>])
  command! -nargs=+ Gdb call luaeval("NvimGdb.here:send(_A[1])", [<q-args>])
  command! GdbLopenBacktrace call luaeval("NvimGdb.here:lopen(require'nvimgdb.app'.lopen_kind.backtrace, '<mods>')")
  command! GdbLopenBreakpoints call luaeval("NvimGdb.here:lopen(require'nvimgdb.app'.lopen_kind.breakpoints, '<mods>')")

  function! GdbCustomCommand(cmd)
    echo "GdbCustomCommand() is deprecated, use Lua `require'nvimgdb'.i(0):custom_command_async()`"
    return luaeval("NvimGdb.here:custom_command(_A[1])", [a:cmd])
  endfunction

  augroup NvimGdb
    au!
    au TabEnter * lua require'nvimgdb'.i(0):on_tab_enter()
    au TabLeave * lua require'nvimgdb'.i(0):on_tab_leave()
    au BufEnter * lua require'nvimgdb'.i(0):on_buf_enter()
    au BufLeave * lua require'nvimgdb'.i(0):on_buf_leave()
    au TabClosed * lua require'nvimgdb'.on_tab_closed()
    au VimLeavePre * lua require'nvimgdb'.on_vim_leave_pre()
  augroup END

  " Define custom events
  augroup NvimGdbInternal
    au!
    au User NvimGdbQuery ""
    au User NvimGdbBreak ""
    au User NvimGdbContinue ""
    au User NvimGdbStart ""
    au User NvimGdbCleanup ""
  augroup END
endfunction

"Shared global state cleanup after the last session ended
function! nvimgdb#GlobalCleanup()
  " Cleanup the autocommands
  call nvimgdb#ClearAugroup("NvimGdb")
  " Cleanup custom events
  call nvimgdb#ClearAugroup("NvimGdbInternal")

  delfunction GdbCustomCommand

  " Cleanup user commands and keymaps
  delcommand GdbDebugStop
  delcommand GdbBreakpointToggle
  delcommand GdbBreakpointClearAll
  delcommand GdbFrame
  delcommand GdbRun
  delcommand GdbUntil
  delcommand GdbContinue
  delcommand GdbNext
  delcommand GdbStep
  delcommand GdbFinish
  delcommand GdbFrameUp
  delcommand GdbFrameDown
  delcommand GdbInterrupt
  delcommand GdbEvalWord
  delcommand GdbEvalRange
  delcommand GdbCreateWatch
  delcommand Gdb
  delcommand GdbLopenBacktrace
  delcommand GdbLopenBreakpoints
endfunction
