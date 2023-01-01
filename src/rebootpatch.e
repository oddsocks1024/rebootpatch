OPT OSVERSION=37,PREPROCESS

MODULE  'dos/dos',
        'exec/memory',
        'exec/nodes',
        'exec/semaphores',
        'exec/ports',
        'exec/tasks',
        'intuition/intuition',
        'tools/patch'

->The tools/patch modules was done by a third party whose
->named escapes me at the moment, but credit to them :)

OBJECT mymsg
    msg:mn
    txt
    t
ENDOBJECT

DEF port:PTR TO mp

PROC main() HANDLE
DEF es=NIL:PTR TO patch,
    sig,
    ps,
    loop=TRUE,
    version

version:='$VER: rebootpatch V1.0 By Ian Chapman'

IF port:=CreateMsgPort()

    NEW es.install(execbase, -726, {reboot}, 5, 200)

    es.enable()
    ps:=Shl(1, port.sigbit)

    WHILE loop
        sig:=Wait(ps OR SIGBREAKF_CTRL_C)
        IF sig AND SIGBREAKF_CTRL_C
            loop:=FALSE
        ENDIF
    ENDWHILE

    es.disable()
    IF es.remove() = FALSE
        WriteF('RebootPatch cannot be removed immediately.\nIt will be automatically removed at the earliest opportunity.\n(Press CTRL + \\ to close window)')
    ENDIF

    DeleteMsgPort(port)

ELSE
    WriteF('Unable to create message port\n')
ENDIF

EXCEPT DO
  END es
ENDPROC


#define REGISTERS a7, a6, a5, a4, a3, a2, a1, a0, d7, d6, d5, d4, d3, d2, d1, d0

PROC reboot(userdata, entry, REGISTERS)

IF (sendhit() = 0)
    MOVE.L d0, D1
    MOVE.L d1, D1   
    MOVE.L d2, D2
    MOVE.L d3, D3
    MOVE.L d4, D4
    MOVE.L d5, D5
    MOVE.L d6, D6
    MOVE.L d7, D7
    MOVE.L a0, A0
    MOVE.L a1, A1
    MOVE.L a2, A2
    MOVE.L a4, A4
    MOVE.L a5, A5
    MOVE.L a3, A3
    MOVE.L a6, A6
ELSE
    MOVE.L d0, D1   -> It might not be necessary to preserve all the registers
    MOVE.L d1, D1   -> for ColdReboot(), but just in case.
    MOVE.L d2, D2
    MOVE.L d3, D3
    MOVE.L d4, D4
    MOVE.L d5, D5
    MOVE.L d6, D6
    MOVE.L d7, D7
    MOVE.L a0, A0
    MOVE.L a1, A1
    MOVE.L a2, A2
    MOVE.L a3, A3
    MOVE.L a6, A6
    MOVE.L A4, -(A7)        -> E uses A4 for global data, preserve it on stack
    MOVE.L entry, A4        -> Place address of unpatched function in A4
    JSR (A4)                -> Run unpatched function
    MOVE.L (A7)+, A4        -> Restore A4 from the stack
ENDIF

ENDPROC


PROC sendhit()
DEF tsk:tc,
    l:ln,
    contents[200]:STRING

tsk:=FindTask(NIL)

IF tsk
    l:=tsk.ln
    IF l AND l.name
        StringF(contents, 'A reboot has been requested by \s', l.name)
    ELSE
        StrCopy(contents, 'A reboot has been requested by an unknown application')
    ENDIF
ELSE
    StrCopy(contents, 'A reboot has been requested by an unknown application')
ENDIF

ENDPROC EasyRequestArgs(NIL, [20, 0, 'Reboot Request (Rebootpatch 1.0)', contents, 'Reboot|Deny'], 0, 0)

