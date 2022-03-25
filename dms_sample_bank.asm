; example multi sample engine 
; 
; use sjasmplus z00m's fork
; em00k2020 / david saphier v1.0
; 
 
z80dmaport  equ $6b
covoxport   equ $ffdf
buffer_size equ 8192
scaler      equ 12  
loop        equ $b2 
noloop      equ $82
 
    device zxspectrumnext
    
    org $8000
    
    ; macro to make initsample clear 
    macro initsample start, length, scalerrepeat 
        ld hl,start : ld de,length  : ld bc,scalerrepeat
        call initdma
    endm 
    ; macro to play a sample from the sample table 
    macro playsample samplenr
        ld c,samplenr : call playsample 
    endm 
    
start
    ; addr fs sample, length of sample and $90 for initial scaler, $00 no loop 
    ; for the sample engine we only want to init the dma, so send a 0 l
    
    ei          ; 0             0                   x90 scaler x01 loop 
    initsample sampletable,sampletable-sampletable, $9001
 
miniloop:
 
samp = 0                                                ; sinple loop which goes through samples 0 - 9 
    rept 10                                             ; rept will repate the following code 10 times, increasing samp+1 
    playsample samp                                     ; each repeat 
    call wait 
samp = samp + 1 
    endr 
    jp miniloop 
    
wait:   
    ld b,60                                             ; small pause 
.wt halt : djnz .wt     
    ret 
 
scalers:
    ; not used in the multisample demo 
    db scaler,scaler*2,scaler*3,scaler*4,scaler*5
    db scaler*6,scaler*7,scaler*8,scaler*9,scaler*10,scaler*12  
    db $ff 
 
playsample: 
    ; sample table is bank x00 loop x00, samplestart x0000, length x0000
    ; 
    ; dw $01dd
    ld d,c : ld e,6 : mul                               ; get offest in sample table 
    ld hl,sampletable                                   ; start of sample table 
    add hl,de                                           ; add offset to samplestart address 
    ld a, (hl) : cp 1 : jr z,.loopedsample              ; chedk for loop 
    ld a,noloop : jr .noloopset     
.loopedsample:
    ld a,loop 
.noloopset:
    ld (dmarepeat),a :  inc hl                          ; now at bank to set 
    ld a, (hl) : nextreg $57,a                          ; set mmu7/$e000 with bank in a 
    inc hl                                              ; now at sample start address x0000
    ld c,(hl) : inc hl : ld a,(hl) : or $e0 : ld b,a    ; or start address with $e000 
    ld (dmaaddress),bc                                  ; store new address in dma code 
    inc hl : ld c,(hl) : inc hl : ld b,(hl)             ; now at length x0000
    ld (dmadlength),bc                                  ; store length in dma length 
    ld bc,$6b : ld a,$87 : out (c),a                    ; reset dma                                         
    jp dmaretrig                                        ; start dma 
    ret 
 
initdma:
 
    ; hl = address de = dmalenght bc = scaler + repeat 
    ld (dmaaddress), hl : ld (dmadlength), de 
    ld a,b : ld (dmascaler),a
dmaretrig:                                              ; send data to dma 
    ld hl,dmasample : ld b,dmaend-dmasample : ld c,z80dmaport : otir
    ret 
 
dmasample:
    defb $c3                                            ;   r6-reset dma
    defb $c7                                            ;   r6-reset port a timing
    defb $ca                                            ;   r6-set port b timing same as port a
    defb $7d                                            ;   r0-transfer mode, a -> b
dmaaddress:                                 
    defw $e000                                          ;   r0-port a, start address
dmadlength:                                 
    defw 8192                                           ;   r0-block length
    defb $54                                            ;    01010100 r1-port a address incrementing, variable timing
    defb $2                                             ;   r1-cycle length port b
    defb $68                                            ;    01101000 r2-port b address fixed, variable timing
    defb $22                                            ;   r2-cycle length port b 2t with pre-escaler
dmascaler:                                  
    defb 8*12                                           ;   r2-port b pre-escaler
    defb $cd                                            ;    11001101 r4-burst mode
    defw covoxport                                      ;   r4-port b, start address
dmarepeat:                                              ;    $b2 for short burst $82 for one shot 
    defb loop                                           ;   r5-stop on end of block, rdy active low
    defb $bb                                            ;    10111011 read mask follows
    defb %00001000                                      ;   mask - only port a hi byte  
    defb $cf                                            ;   r6-load
    defb $b3                                            ;   r6-force ready
    defb $87                                            ;   r6-enable dma         
dmaend: 
 
sampletable:
    
    ; bank, start, len 
    ; 8bk bank + loop , offset from bank start, lenth - must be a better way to store this. 
    ; bank x00 loop x00, samplestart x0000, length x0000
    dw $0f01, 0000                  , 944               ; 0 mothership looped 
    dw $0f00, 0945                  , 1911              ; 1 steam       
    dw $1000, 0000                  , 7313              ; 2 explode    
    dw $1101, 0000                  , 2529              ; 3 zapzapdii  looped 
    dw $1100, 2529                  , 405               ; 4 dub1    
    dw $1100, 2529+405              , 363               ; 5 dub2 
    dw $1100, 2529+405+363          , 382               ; 6 dub3
    dw $1100, 2529+405+363+382      , 489               ; 7 dub4
    dw $1101, 2529+405+363+382+489  , 917               ; 8 wawawawa   looped 
    dw $1201, 0000                  , 6014              ; 9 zzzzrrrttt looped 
    dw $ffff 
    
    slot 7                                              ; slot 7 is mmu 7 @ 0xe000..0xffff
    page $f : org $e000                                 ; page 15/$f is a next mmu bank 8kb nr $f , we have to org $e000 
    incbin "0.pcm"                                      ; as that is where we want this code to go
    incbin "1.pcm"                                      ; and we only have 8kb per bank free 
    page $10 : org $e000                                ; next mmu bank $10, starting at $e000 again 
    incbin "2.pcm"  
    page $11 : org $e000                                ; repeate for remaining samples 
    incbin "3.pcm"                                      ; these are small samples  
    incbin "4.pcm"  
    incbin "5.pcm"  
    incbin "6.pcm"                                      ; unisgned 5512hz samples raw, no header. 
    incbin "7.pcm"  
    incbin "8.pcm" 
    page $12 : org $e000
    incbin "18.pcm" 
 
    savenex open "sampleengine.nex", start , $bffe
    savenex core 3, 0, 0      
    savenex cfg  0, 0            
    savenex auto
    savenex close