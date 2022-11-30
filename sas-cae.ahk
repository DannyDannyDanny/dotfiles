; this file contains two mods: shift-and-space and control-and-escape

; shift-and-space script
; source: https://stackoverflow.com/a/39226212
#InputLevel, 10  ;set send level for the following code to 10
$Space::
#InputLevel  ;set it back to default value of 0 for any remaining code
now := A_TickCount
while GetKeyState("Space", "P") ; to find out whether space-bar is held
    if (A_TickCount-now > 100) ; this time is tested on asker's computer
    {
        SendInput {Shift Down}
        KeyWait, Space
        SendInput {Shift Up}
        return
    }


SendInput {Space} ; if key detected to be tapped, send space as per normal
return


; control-and-escape script
; source: https://gist.github.com/nocaoper/b872f97cda29bd8f0f2617606abd9fe4
LShift & Capslock::
SetCapsLockState, % (State:=!State) ? "on" : "alwaysoff"
Return

g_AbortSendEsc := false

#InstallKeybdHook
SetCapsLockState, alwaysoff
Capslock::
g_DoNotAbortSendEsc := true
Send {LControl Down}
KeyWait, CapsLock
Send {LControl Up}
if ( A_PriorKey = "CapsLock")
{
	if(g_DoNotAbortSendEsc){
		Send {Esc}
	}
}
return

~*^a::
~*^b::
~*^c::
~*^d::
~*^e::
~*^f::
~*^g::
~*^h::
~*^i::
~*^j::
~*^k::
~*^l::
~*^m::
~*^n::
~*^o::
~*^p::
~*^q::
~*^r::
~*^s::
~*^t::
~*^u::
~*^v::
~*^w::
~*^x::
~*^y::
~*^z::
~*^1::
~*^2::
~*^3::
~*^4::
~*^5::
~*^6::
~*^7::
~*^8::
~*^9::
~*^0::
~*^Space::
~*^Backspace::
~*^Delete::
~*^Insert::
~*^Home::
~*^End::
~*^PgUp::
~*^PgDn::
~*^Tab::
~*^Return::
~*^,::
~*^.::
~*^/::
~*^;::
~*^'::
~*^[::
~*^]::
~*^\::
~*^-::
~*^=::
~*^`::
~*^F1::
~*^F2::
~*^F3::
~*^F4::
~*^F5::
~*^F6::
~*^F7::
~*^F8::
~*^F9::
~*^F10::
~*^F11::
~*^F12::
    g_DoNotAbortSendEsc := false
    return
