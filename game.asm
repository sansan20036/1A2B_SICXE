GAME     START 1000

. Main flow: show header, start a round, then loop until win/lose.
MAIN     +LDB  #DATA
         BASE  DATA
         JSUB  PHDR
NROUND   JSUB  INIT
         JSUB  PSED
         JSUB  READLN
         JSUB  MKSEED
         JSUB  MKSEC
         JSUB  PRDY

. One guess round: show history, prompt, validate, then score.
GLOOP    JSUB  PHIST
         JSUB  PGSS
         JSUB  READLN
         JSUB  VALG
         LDA   VALID
         COMP  #1
         JEQ   GCALC
         JSUB  PINV
         J     GLOOP

. Valid guesses reach here. Only valid guesses increase GUESSC.
GCALC    JSUB  CHKAB
         LDA   GUESSC
         ADD   #1
         STA   GUESSC
         JSUB  SAVHIS
         JSUB  SHRES
         LDA   ACNT
         COMP  #4
         JEQ   GWIN
         LDA   GUESSC
         COMP  #8
         JEQ   GLOSE
         J     GLOOP

. After win/lose, ask whether to start a fresh round or halt forever.
GWIN     JSUB  PWIN
         J     RPTLP
GLOSE    JSUB  PLOSE
RPTLP    JSUB  PREPT
         JSUB  READLN
         LDA   INLEN
         COMP  #0
         JEQ   HALT
         CLEAR X
         CLEAR A
         LDCH  INBUF,X
         COMP  #89
         JEQ   NROUND
         COMP  #121
         JEQ   NROUND
         COMP  #78
         JEQ   HALT
         COMP  #110
         JEQ   HALT
         JSUB  PRERR
         J     RPTLP

. SicTools VM stops only when execution stays on the same address.
HALT     J     HALT

. Reset per-round state. Header text is only shown once from MAIN.
INIT     LDA   #0
         STA   ACNT
         STA   BCNT
         STA   VALID
         STA   INLEN
         STA   RAND
         STA   OUTI
         STA   INRI
         STA   SECPOS
         STA   DUPFLG
         STA   GUESSC
         RSUB

. Read one line from device 0 into INBUF, skipping CR and ending on LF.
READLN   CLEAR X
. RDLP reads normal characters until LF or buffer-full.
RDLP     CLEAR A
RDIWT    TD    INDEV
         JEQ   RDIWT
         RD    INDEV
         COMP  #13
         JEQ   RDLP
         COMP  #10
         JEQ   RDDN
         STCH  INBUF,X
         TIX   #31
         JLT   RDLP
. RDFULL discards extra input until LF so the next read starts cleanly.
RDFULL   CLEAR A
RDFWT    TD    INDEV
         JEQ   RDFWT
         RD    INDEV
         COMP  #13
         JEQ   RDFULL
         COMP  #10
         JEQ   RDDN
         J     RDFULL
. Store final length in INLEN and append a zero terminator.
RDDN     STX   INLEN
         CLEAR A
         STCH  INBUF,X
         RSUB

. Build the seed used by MKSEC.
. Blank input reads bytes from device 03; non-blank input hashes the typed text.
MKSEED   STL   RETSED
         LDA   INLEN
         COMP  #0
         JGT   MKS1
         LDA   DEFSED
         STA   RAND
         LDA   #0
         STA   OUTI
. RNDLOP mixes 8 bytes from file device 03 into RAND.
RNDLOP   LDA   OUTI
         COMP  #8
         JLT   RNDRD
         LDL   RETSED
         RSUB
RNDRD    CLEAR A
RNDWT    TD    RNDDEV
         JEQ   RNDWT
         RD    RNDDEV
         STA   CHARI
         LDA   RAND
         MUL   #251
         ADD   CHARI
         ADD   OUTI
         ADD   #1
         STA   RAND
         LDA   MOD10K
         STA   MODDIV
         LDA   RAND
         JSUB  MODULO
         STA   RAND
         LDA   OUTI
         ADD   #1
         STA   OUTI
         J     RNDLOP
. MKS1/MKSLOP hash the typed seed text one byte at a time.
MKS1     LDA   #0
         STA   RAND
         STA   OUTI
MKSLOP   LDA   OUTI
         COMP  INLEN
         JLT   MKSCH
         LDL   RETSED
         RSUB
MKSCH    LDX   OUTI
         CLEAR A
         LDCH  INBUF,X
         STA   CHARI
         LDA   RAND
         MUL   #17
         ADD   CHARI
         STA   RAND
         LDA   MOD10K
         STA   MODDIV
         LDA   RAND
         JSUB  MODULO
         STA   RAND
         LDA   OUTI
         ADD   #1
         STA   OUTI
         J     MKSLOP

. Generate a 4-digit secret with no repeated digits.
. RETSEC stores L because this routine calls MODULO and CHKDUP.
MKSEC    STL   RETSEC
         LDA   #0
         STA   SECPOS
. MSLP stops after 4 distinct digits have been written to SECRET.
MSLP     LDA   SECPOS
         COMP  #4
         JLT   MSGEN
         LDL   RETSEC
         RSUB
. MSGEN advances RAND, then converts it into a digit candidate.
MSGEN    LDA   RAND
         MUL   #17
         ADD   #31
         STA   RAND
         LDA   MOD10K
         STA   MODDIV
         LDA   RAND
         JSUB  MODULO
         STA   RAND
MSRETY   LDA   #10
         STA   MODDIV
         LDA   RAND
         JSUB  MODULO
         ADD   #48
         STA   CAND
. CHKDUP sets DUPFLG when the digit already exists in SECRET.
         JSUB  CHKDUP
         LDA   DUPFLG
         COMP  #1
         JEQ   MSDUP
         LDX   SECPOS
         LDA   CAND
         STCH  SECRET,X
         LDA   SECPOS
         ADD   #1
         STA   SECPOS
         J     MSLP
. On duplicates, bump RAND and retry only the candidate step.
MSDUP    LDA   RAND
         ADD   #1
         STA   RAND
         J     MSRETY

. Check whether the candidate digit is already present in SECRET.
CHKDUP   LDA   #0
         STA   DUPFLG
         STA   INRI
. CDLOP scans SECRET[0..SECPOS-1].
CDLOP    LDA   INRI
         COMP  SECPOS
         JLT   CDCMP
         RSUB
CDCMP    LDX   INRI
         CLEAR A
         LDCH  SECRET,X
         COMP  CAND
         JEQ   CDYES
         LDA   INRI
         ADD   #1
         STA   INRI
         J     CDLOP
CDYES    LDA   #1
         STA   DUPFLG
         RSUB

. Validate guess format: exactly 4 ASCII digits and no duplicates.
VALG     LDA   #0
         STA   VALID
         LDA   INLEN
         COMP  #4
         JEQ   VSTRT
         RSUB
. VOUTLP walks each character, VINLP compares it with later characters.
VSTRT    LDA   #1
         STA   VALID
         LDA   #0
         STA   OUTI
VOUTLP   LDA   OUTI
         COMP  #4
         JLT   VCHAR
         RSUB
VCHAR    LDX   OUTI
         CLEAR A
         LDCH  INBUF,X
         STA   CHARI
         COMP  #48
         JLT   VBAD
         COMP  #57
         JGT   VBAD
         LDA   OUTI
         ADD   #1
         STA   INRI
VINLP    LDA   INRI
         COMP  #4
         JLT   VCMP
         LDA   OUTI
         ADD   #1
         STA   OUTI
         J     VOUTLP
VCMP     LDX   INRI
         CLEAR A
         LDCH  INBUF,X
         COMP  CHARI
         JEQ   VBAD
         LDA   INRI
         ADD   #1
         STA   INRI
         J     VINLP
VBAD     LDA   #0
         STA   VALID
         RSUB

. Count A and B for the current guess.
CHKAB    LDA   #0
         STA   ACNT
         STA   BCNT
         STA   OUTI
. ABO iterates over each guess position.
ABO      LDA   OUTI
         COMP  #4
         JLT   ABO1
         RSUB
ABO1     LDX   OUTI
         CLEAR A
         LDCH  INBUF,X
         STA   CHARI
         CLEAR A
         LDCH  SECRET,X
         COMP  CHARI
         JEQ   ADDA
         LDA   #0
         STA   INRI
. ABI scans the full secret when the current position is not an A.
ABI      LDA   INRI
         COMP  #4
         JLT   ABIC
         J     ABNXT
ABIC     LDX   INRI
         CLEAR A
         LDCH  SECRET,X
         COMP  CHARI
         JEQ   ADDB
         LDA   INRI
         ADD   #1
         STA   INRI
         J     ABI
ADDB     LDA   BCNT
         ADD   #1
         STA   BCNT
         J     ABNXT
ADDA     LDA   ACNT
         ADD   #1
         STA   ACNT
ABNXT    LDA   OUTI
         ADD   #1
         STA   OUTI
         J     ABO

. Return A mod MODDIV. Used for both hashing and digit generation.
MODULO   STA   MODOR
         DIV   MODDIV
         STA   MODQT
         MUL   MODDIV
         STA   MODPD
         LDA   MODOR
         SUB   MODPD
         RSUB

. WROUT waits for device 1 to become ready, then writes A low byte.
WROUT    TD    OUTDEV
         JEQ   WROUT
         WD    OUTDEV
         RSUB

PHDR     CLEAR X
PHDRL    CLEAR A
         LDCH  MSGHDR,X
         COMP  #0
         JEQ   PHDRD
PHDRW    TD    OUTDEV
         JEQ   PHDRW
         WD    OUTDEV
         TIX   #255
         J     PHDRL
PHDRD    RSUB

. Prompt for seed entry.
PSED     CLEAR X
PSEDL    CLEAR A
         LDCH  MSGSED,X
         COMP  #0
         JEQ   PSEDD
PSEDW    TD    OUTDEV
         JEQ   PSEDW
         WD    OUTDEV
         TIX   #255
         J     PSEDL
PSEDD    RSUB

. Confirm a new secret was generated.
PRDY     CLEAR X
PRDYL    CLEAR A
         LDCH  MSGRDY,X
         COMP  #0
         JEQ   PRDYD
PRDYW    TD    OUTDEV
         JEQ   PRDYW
         WD    OUTDEV
         TIX   #255
         J     PRDYL
PRDYD    RSUB

. Prompt for the next guess.
PGSS     CLEAR X
PGSSL    CLEAR A
         LDCH  MSGGSS,X
         COMP  #0
         JEQ   PGSSD
PGSSW    TD    OUTDEV
         JEQ   PGSSW
         WD    OUTDEV
         TIX   #255
         J     PGSSL
PGSSD    RSUB

. Print invalid-input message and return to GLOOP.
PINV     CLEAR X
PINVL    CLEAR A
         LDCH  MSGINV,X
         COMP  #0
         JEQ   PINVD
PINVW    TD    OUTDEV
         JEQ   PINVW
         WD    OUTDEV
         TIX   #255
         J     PINVL
PINVD    RSUB

. Save the latest valid guess and its A/B result into the history buffers.
SAVHIS   LDA   GUESSC
         SUB   #1
         STA   HIDX
         LDX   HIDX
         LDA   #INBUF
         STA   INPTR
         CLEAR A
         LDCH  @INPTR
         STCH  HIST1,X
         LDA   INPTR
         ADD   #1
         STA   INPTR
         CLEAR A
         LDCH  @INPTR
         STCH  HIST2,X
         LDA   INPTR
         ADD   #1
         STA   INPTR
         CLEAR A
         LDCH  @INPTR
         STCH  HIST3,X
         LDA   INPTR
         ADD   #1
         STA   INPTR
         CLEAR A
         LDCH  @INPTR
         STCH  HIST4,X
         LDA   ACNT
         ADD   #48
         STCH  HISTA,X
         LDA   BCNT
         ADD   #48
         STCH  HISTB,X
         RSUB

. Print all previous valid guesses before asking for the next one.
. Example: "#3 Guess: 1234 Result: 1A2B Left: 5"
PHIST    STL   RETPHI
         LDA   GUESSC
         COMP  #0
         JEQ   PHIDN
         CLEAR X
. PHIHD prints the "History:" heading once per prompt cycle.
PHIHD    CLEAR A
         LDCH  MSGHIS,X
         COMP  #0
         JEQ   PHIST0
         JSUB  WROUT
         TIX   #255
         J     PHIHD
PHIST0   LDA   #0
         STA   HIDX
. PHILO iterates rows 0..GUESSC-1 from the history buffers.
PHILO    LDA   HIDX
         COMP  GUESSC
         JLT   PHIRW
PHIDN    LDL   RETPHI
         RSUB
. PHIIN emits fixed leading spaces to fake a right-side column.
PHIRW    LDA   #35
         CLEAR X
PHIIN    CLEAR A
         LDCH  MSGIND,X
         COMP  #0
         JEQ   PHIROW
         JSUB  WROUT
         TIX   #255
         J     PHIIN
PHIROW   LDA   #35
         JSUB  WROUT
         LDA   HIDX
         ADD   #1
         JSUB  PDEC
         CLEAR X
PHIGS    CLEAR A
         LDCH  MSGHG,X
         COMP  #0
         JEQ   PHIGD
         JSUB  WROUT
         TIX   #255
         J     PHIGS
. PHIGD prints the stored 4-digit guess for the current history row.
PHIGD    LDX   HIDX
         CLEAR A
         LDCH  HIST1,X
         JSUB  WROUT
         CLEAR A
         LDCH  HIST2,X
         JSUB  WROUT
         CLEAR A
         LDCH  HIST3,X
         JSUB  WROUT
         CLEAR A
         LDCH  HIST4,X
         JSUB  WROUT
         CLEAR X
PHIRS    CLEAR A
         LDCH  MSGHR,X
         COMP  #0
         JEQ   PHIRD
         JSUB  WROUT
         TIX   #255
         J     PHIRS
. PHIRD prints stored A/B, then PHILD prints remaining guesses at that time.
PHIRD    LDX   HIDX
         CLEAR A
         LDCH  HISTA,X
         JSUB  WROUT
         LDA   #65
         JSUB  WROUT
         CLEAR A
         LDCH  HISTB,X
         JSUB  WROUT
         LDA   #66
         JSUB  WROUT
         CLEAR X
PHILS    CLEAR A
         LDCH  MSGLEFT,X
         COMP  #0
         JEQ   PHILD
         JSUB  WROUT
         TIX   #255
         J     PHILS
PHILD    LDA   #8
         SUB   HIDX
         SUB   #1
         JSUB  PDEC
         LDA   #10
         JSUB  WROUT
         LDA   HIDX
         ADD   #1
         STA   HIDX
         J     PHILO

. Print "Guess #n: xAyB".
SHRES    STL   RETSHR
         CLEAR X
. SRLOP prints the "Guess #" prefix before the numbers.
SRLOP    CLEAR A
         LDCH  MSGRES,X
         COMP  #0
         JEQ   SRCNT
         JSUB  WROUT
         TIX   #255
         J     SRLOP
SRCNT    LDA   GUESSC
         JSUB  PDEC
         LDA   #58
         JSUB  WROUT
         LDA   #32
         JSUB  WROUT
         LDA   ACNT
         ADD   #48
         JSUB  WROUT
         LDA   #65
         JSUB  WROUT
         LDA   BCNT
         ADD   #48
         JSUB  WROUT
         LDA   #66
         JSUB  WROUT
         LDA   #10
         JSUB  WROUT
         LDL   RETSHR
         RSUB

. Print the decimal value in A without leading zeros.
. Supports values 0..999, which is enough for guess counters here.
PDEC     STL   RETDEC
         STA   NUMVAL
         DIV   #100
         STA   NUMHUN
         MUL   #100
         STA   NUMTMP
         LDA   NUMVAL
         SUB   NUMTMP
         STA   NUMREM
         DIV   #10
         STA   NUMTEN
         MUL   #10
         STA   NUMTMP
         LDA   NUMREM
         SUB   NUMTMP
         STA   NUMONE
         LDA   NUMHUN
         COMP  #0
         JEQ   PDECT
         ADD   #48
         JSUB  WROUT
         LDA   NUMTEN
         ADD   #48
         JSUB  WROUT
         J     PDECO
PDECT    LDA   NUMTEN
         COMP  #0
         JEQ   PDECO
         ADD   #48
         JSUB  WROUT
PDECO    LDA   NUMONE
         ADD   #48
         JSUB  WROUT
         LDL   RETDEC
         RSUB

. Print win message.
. These short print routines all stream a zero-terminated message buffer.
PWIN     CLEAR X
PWINL    CLEAR A
         LDCH  MSGWIN,X
         COMP  #0
         JEQ   PWIND
PWINW    TD    OUTDEV
         JEQ   PWINW
         WD    OUTDEV
         TIX   #255
         J     PWINL
PWIND    RSUB

. Print lose message and reveal the 4-digit secret.
. PLOSC/PLOSS dump SECRET byte-by-byte after the lose message.
PLOSE    CLEAR X
PLOSL    CLEAR A
         LDCH  MSGLOS,X
         COMP  #0
         JEQ   PLOSC
PLOSW    TD    OUTDEV
         JEQ   PLOSW
         WD    OUTDEV
         TIX   #255
         J     PLOSL
PLOSC    CLEAR X
PLOSS    CLEAR A
         LDCH  SECRET,X
PLOSCW   TD    OUTDEV
         JEQ   PLOSCW
         WD    OUTDEV
         TIX   #4
         JLT   PLOSS
         LDA   #10
PLOSNW   TD    OUTDEV
         JEQ   PLOSNW
         WD    OUTDEV
         RSUB

. Prompt for replay and reject anything other than Y/N.
. PREPT prints the question, PRERR prints the retry message for bad input.
PREPT    CLEAR X
PREPL    CLEAR A
         LDCH  MSGRPT,X
         COMP  #0
         JEQ   PREPD
PREPW    TD    OUTDEV
         JEQ   PREPW
         WD    OUTDEV
         TIX   #255
         J     PREPL
PREPD    RSUB

PRERR    CLEAR X
PRERL    CLEAR A
         LDCH  MSGRER,X
         COMP  #0
         JEQ   PRERD
PRERW    TD    OUTDEV
         JEQ   PRERW
         WD    OUTDEV
         TIX   #255
         J     PRERL
PRERD    RSUB

. Devices and mutable game state.
DATA     BYTE  X'00'
INDEV    BYTE  X'00'
OUTDEV   BYTE  X'01'
RNDDEV   BYTE  X'03'
SECRET   RESB  4
INBUF    RESB  32
INLEN    RESW  1
ACNT     RESW  1
BCNT     RESW  1
VALID    RESW  1
RAND     RESW  1
OUTI     RESW  1
INRI     RESW  1
SECPOS   RESW  1
DUPFLG   RESW  1
GUESSC   RESW  1
HIDX     RESW  1
INPTR    RESW  1
CHARI    RESW  1
CAND     RESW  1
MODDIV   RESW  1
MODOR    RESW  1
MODQT    RESW  1
MODPD    RESW  1
RETSED   RESW  1
RETSEC   RESW  1
RETDEC   RESW  1
RETSHR   RESW  1
RETPHI   RESW  1
NUMVAL   RESW  1
NUMHUN   RESW  1
NUMTEN   RESW  1
NUMONE   RESW  1
NUMREM   RESW  1
NUMTMP   RESW  1
HIST1    RESB  8
HIST2    RESB  8
HIST3    RESB  8
HIST4    RESB  8
HISTA    RESB  8
HISTB    RESB  8
DEFSED   WORD  1357
MOD10K   WORD  10000

. User-facing text.
MSGHDR   BYTE  C'==== 1A2B GAME ===='
         BYTE  X'0A'
         BYTE  C'Guess 4 different digits.'
         BYTE  X'0A'
         BYTE  X'00'
MSGSED   BYTE  C'Seed text (Game START Enter): '
         BYTE  X'00'
MSGRDY   BYTE  C'Secret ready. Start guessing.'
         BYTE  X'0A'
         BYTE  X'00'
MSGGSS   BYTE  C'Your guess: '
         BYTE  X'00'
MSGINV   BYTE  C'Invalid input. Use 4 different digits.'
         BYTE  X'0A'
         BYTE  X'00'
MSGHIS   BYTE  C'                    History:'
         BYTE  X'0A'
         BYTE  X'00'
MSGIND   BYTE  C'                    '
         BYTE  X'00'
MSGHG    BYTE  C' Guess: '
         BYTE  X'00'
MSGHR    BYTE  C' Result: '
         BYTE  X'00'
MSGRES   BYTE  C'Guess #'
         BYTE  X'00'
MSGWIN   BYTE  C'You got 4A0B. You win.'
         BYTE  X'0A'
         BYTE  X'00'
MSGLOS   BYTE  C'You used 8 guesses. You lose. Secret: '
         BYTE  X'00'
MSGLEFT  BYTE  C' Left: '
         BYTE  X'00'
MSGRPT   BYTE  C'Play again? (Y/N): '
         BYTE  X'00'
MSGRER   BYTE  C'Please type Y or N.'
         BYTE  X'0A'
         BYTE  X'00'

         END   MAIN
