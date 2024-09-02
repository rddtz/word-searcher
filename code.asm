CR equ 0DH
LF equ 0AH
MAX_STR equ 25
BUFFERSIZE equ 1000

.model small
.stack
.data

	caminhoArq DB MAX_STR + 1 dup(0), 0
	
	safeguard DW 0 ; Just to confirm that before the buffer i have only zeros (used to check context)
	buffer DB BUFFERSIZE dup(0), 0 ; Where everything lives
	
	lido DB MAX_STR + 1 dup(0), 0
	
	endl DB CR, LF, '$'
	
	handle DW 0
	char DB 0
	upped DB 0 ; Variable to get char in uppercase
	
	linha DW 0
	flag_achadas DB 0
	
	erro DB 0
	flag_inv DB 0
	
	erro_ao_abrir DB 'Erro ao abrir o arquvio', CR, LF, '$'
	erro_ao_fechar DB 'Erro ao fechar o arquvio', CR, LF, '$'
	erro_ao_ler DB 'Erro ao ler do arquvio', CR, LF, '$'
	
	letras_lidas DB CR,LF,'Letras Lidas: ', '$'
	
	lido_string DB CR,LF,'Lido: ', '$'
	
	prompt_palavra DB '-- Que palavra voce quer buscar?', CR, LF, '$'
	flag_idiota DB 0
	
	prompt_encontradas DB CR, LF, '-- Foram encontradas as seguintes ocorrencias:', CR, LF, '$'
	prompt_nao_encontradas DB CR, LF, '-- Nao foram encontradas ocorrencias.', CR, LF, '$'
	
	prompt_fim DB '-- Fim das ocorrencias.', CR, LF, '$'
	
	prompt_mais DB '-- Quer buscar outra palavra? (S/N)', CR, LF, '$'
	prompt_inv DB CR, LF, '-- Por favor, responda somente S ou N.', CR, LF, '$'

	encerrando DB CR, LF, '-- Encerrando.', '$'
	
	achado_linha DB 'Linha ','$'
	
.code
	.startup
	
		CALL argv ;Pega o caminho atual do arquivo
		
		MOV AX, DS       
		MOV ES, AX ; Set ES and DS to same position
	
		CALL openf
		XOR CX, CX
		MOV CH, erro
		OR CX, CX
		JNZ fim_erro
	
		pesquisas:
		
		MOV AX, 0
		INC AX
		MOV linha, AX
		
		MOV AL, flag_idiota
		OR AL, AL
		JZ print_primeira_vez_sem_o_endl
		
		LEA DX, endl
		CALL prints
		LEA DX, prompt_palavra ; Pergunta que palavra quer procurar
		CALL prints
		
		finge_que_nada_aconteceu:
		
		LEA DI, lido
		CALL scanfs
		
		LEA SI, lido
		CALL check_valid
		MOV CL, flag_inv
		OR CL, CL
		JNZ pesquisa_invalida
		
		LEA SI, lido
		CALL upper
			
		busca:
		
			CALL getline ; Arrumar isso e ta quase
			OR AX, AX
			JZ last_search
			XOR CX, CX
			MOV CH, erro
			OR CX, CX
			JNZ fim_erro
			
			;LEA DX, buffer
			;CALL prints
			
			CALL find
			
			MOV AX, linha
			INC AX
			MOV linha, AX
			
			JMP busca
		
		last_search:

		XOR CX, CX
		MOV CH, erro
		OR CX, CX
		JNZ fim_erro
		
		CALL find
		
		MOV DL, flag_achadas
		OR DL, DL
		JNZ fim_ocorrencias
		
		LEA DX, prompt_nao_encontradas
		CALL prints
		JMP fechar_arquivo
		
		fim_ocorrencias:
		LEA DX, prompt_fim
		CALL prints
		
		fechar_arquivo:
		CALL closef
		XOR CX, CX
		MOV CH, erro
		OR CX, CX
		JNZ fim_erro

		CALL openf ; Modularizar
		XOR CX, CX
		MOV CH, erro
		OR CX, CX
		JNZ fim_erro
		
		XOR AX, AX
		MOV flag_achadas, AL
	
		perguntando:
		
		LEA DX, prompt_mais
		CALL prints
		
		LEA DI, lido
		CALl scanfs
		
		LEA DI, lido
		CMP byte ptr [DI + 1], '$'
		JE maybe_valido
	
		invalido:
		
		LEA DX, prompt_inv
		CALL prints
		
		JMP perguntando
		
		maybe_valido:
			MOV DL, byte ptr [DI]
			MOV upped, DL
			CALL upper_c 
			MOV DL, upped
			
			CMP DL, 'S'
			JE pesquisas
		
			MOV DL, upped
			CMP DL, 'N'
			JE fim
		
			JMP invalido
		
		pesquisa_invalida:
			XOR CL, CL
			MOV flag_inv, CL
			JMP caso_pesquisa_invalida
			
		print_primeira_vez_sem_o_endl:
		
			INC AX
			MOV flag_idiota, AL
		caso_pesquisa_invalida:
			LEA DX, prompt_palavra ; Pergunta que palavra quer procurar
			CALL prints
			
			JMP finge_que_nada_aconteceu
		
			;erro while oppening or closing
		fim:
		LEA DX, encerrando
		CALL prints
		
		fim_erro:
	.exit

check_valid PROC FAR

	loop_check:
	
		XOR DX, DX
		MOV DL, byte ptr [SI]
		
		CMP DL, '$'
		JZ end_checking
		
		CMP DL, ' '
		JE invalid_search
		
		CMP DL, '.'
		JE invalid_search
		
		CMP DL, ','
		JE invalid_search
		
		CMP DL, '!'
		JE invalid_search
		
		CMP DL, '?'
		JE invalid_search
		
		CMP DL, ':'
		JE invalid_search
		
		CMP DL, ';'
		JE invalid_search
	
		INC SI
		JMP loop_check
	
	invalid_search:
		LEA DX, endl
		CALL prints
		MOV DX, 1
		MOV flag_inv, DL
	
	end_checking:
	RET
check_valid ENDP

; Upper string on SI
upper PROC FAR

	loop_upper:
	
		XOR DX, DX
		MOV DL, byte ptr [SI]
		
		CMP DL, 0
		JZ fim_upper
	
		CMP DL, 97
		JB next_upper
		
		CMP DL, 122
		JG next_upper
		
		SUB DL, ' '
		
		MOV [SI], byte ptr DL
	
		next_upper:
		
		INC SI
		JMP loop_upper
	
	fim_upper:
	RET

upper ENDP

; Get the character in upped and return it in uppercase
upper_c PROC FAR

	XOR DX, DX
	MOV DL, upped
	
	CMP DL, 97
	JB fim_upperc
		
	CMP DL, 122
	JG fim_upperc
		
	SUB DL, ' '
	MOV upped, DL
		
	fim_upperc:
	RET

upper_c ENDP

argv PROC FAR

	PUSH DS ; Salva as informacoes de segmentos
	PUSH ES
	MOV AX, DS ; Troca DS com ES para poder usa o REP MOVSB
	MOV BX, ES
	MOV DS, BX
	MOV ES, AX

	MOV SI, 80h ; Obtem o tamanho da linha de comando e coloca em CX
	XOR CX, CX
	MOV CL, [SI]
	
	XOR BX, BX
	MOV BX, [SI]
	
	MOV AX, CX ; Salva o tamanho do string em AX, para uso futuro
	
	MOV SI, 81h ; Inicializa o ponteiro de origem
	LEA DI, caminhoArq - 1 ; Inicializa o ponteiro de destino
	
	REP MOVSB

	POP ES ; retorna os dados dos registradores de segmentos
	POP DS

	RET

argv ENDP

; Function to OPEN a file ===========================
openf PROC FAR

	MOV AH, 3DH
	XOR AL, AL
	
	LEA DX, caminhoArq
	
	INT 21H
	
	JNC FimSuccessA
	
		LEA DX, erro_ao_abrir
		CALL prints
		
		MOV CH, erro
		INC CH
		MOV erro, CH
		
		JMP FimErroA
		
	FimSuccessA:
	
		MOV handle, AX
	
	FimErroA:

	RET

openf ENDP
	
; Function to CLOSE a file ===========================
closef PROC FAR

	XOR AX, AX
	MOV AH, 3EH
	MOV BX, handle
	
	INT 21H
	
	JNC FimSuccessF

	LEA DX, erro_ao_fechar
	CALL prints
	MOV DX, 1
	MOV erro, DL
	
	FimSuccessF:
	
	RET

closef ENDP	

; Function to get 1 char from a file ===========================
getc PROC FAR

	MOV AH, 3FH
	MOV BX, handle
	MOV CX, 1
	LEA DX, char
	
	INT 21H
	
	RET

getc ENDP


; Reads up to 25 characters from keyboard to string loaded in DI before call (LEA DI, string) (MAX_STR = 25)
; Puts '$' at the end of String
scanfs PROC FAR

	XOR AX, AX
	
	MOV AH, 0AH
	LEA DX, buffer
	
	MOV	byte ptr buffer, MAX_STR + 1 ;
	
	INT	21H
	
	; Move buffer to lido string ==========
	LEA	SI, buffer+2				
	
	XOR CX, CX
	MOV	CL, buffer+1 ; <------ERRO Verificar se é maior que a string
	
	CMP CL, MAX_STR
	JBE valid_size
	
	MOV CL, MAX_STR
	
	valid_size:
	
	REP MOVSB
	
	MOV	byte ptr ES:[DI],'$'
	;==============
	
	RET

scanfs ENDP

; Get one line from file to buffer
getline PROC FAR

	XOR AX, AX
	
	LEA DI, buffer
	
	loop_getline:
		MOV AH, 03FH
		MOV BX, handle
		MOV CX, 1
		MOV DX, DI
		INT	21H	
			
		JC erro_getline
		
		OR AX, AX
		JZ fim_arquivo
		
		XOR DX, DX
		MOV DL,	[DI]
		
		CMP DX, CR
		JE ok_getline
		
		INC DI
	
		JMP loop_getline
		
	erro_getline:
		LEA DX, erro_ao_ler
		CALL prints
		MOV DX, 1
		MOV erro, DL
		
		JMP end_getline
		
	fim_arquivo:
		MOV	byte ptr ES:[DI], CR
		INC DI
		
		MOV	byte ptr ES:[DI], LF
		
		JMP dollar_sign_at_the_end
		
	ok_getline:
	
		INC DI
		CALL getc
		MOV DL, char
		
		MOV	byte ptr ES:[DI], DL
		
	dollar_sign_at_the_end:
		
		INC DI
		MOV	byte ptr ES:[DI],'$'
		
	end_getline:
	RET

getline ENDP

; Function to print a string ===========================
prints PROC FAR

	XOR AX, AX
	MOV AH, 09H
	INT 21H
	
	RET

prints ENDP

; Function to print one char on DX ===========================
printc PROC FAR

	XOR AX, AX
	MOV AH, 02H
	INT 21H
	
	RET

printc ENDP

; Function to print a number ===========================
printn proc near ; Number in AX

	XOR CX, CX
	XOR DX, DX
	
	OR AX,AX
	JZ zerocase
	
	loopn:
	
		OR AX,AX
		JZ actual_printn
		
		MOV BX,10
		DIV BX
		
		PUSH DX
		
		XOR DX,DX
		
		INC CX
	
		JMP loopn

	actual_printn:
	
		OR CX, CX
		JZ fimn
		
		POP DX
		
		ADD DX, '0'
		
		CALL printc
		
		DEC CX
		
		JMP actual_printn
		
	fimn:
		RET
		
	zerocase:
		MOV DX, '0'
		CALL printc
		JMP fimn
	
printn	endp


;; Arrumar isso que que não funciona por nada
find PROC FAR
	
	LEA DI, buffer ; Buffer with the line
	LEA SI, lido ; String he wanna found
	
	loop_tryfind:
		
		XOR DX, DX
		MOV DL, byte ptr [DI]
		MOV upped, DL
		CALL upper_c 
		MOV DL, upped ; Move upper case character pointed by [DI] to DL
		
		INC DI
		
		CMP DL, byte ptr [SI]
		JE maybe_equal
		
		CMP byte ptr [SI], '$'
		JE check_found
		
	continue_find:
		LEA SI, lido ; Resets SI and go to nextword 
		
	nextword:
		
		CMP byte ptr [DI - 1], ' '
		JE loop_tryfind
		
		CMP byte ptr [DI], CR
		JE end_find
		
		CMP byte ptr [DI - 1], CR
		JE end_find
		
		INC DI
		JMP nextword
	
	maybe_equal:
		
		INC SI
		JMP loop_tryfind
	
	check_found:
		
		CMP byte ptr [DI - 1], ' '
		JE found
		
		CMP byte ptr [DI - 1], '.'
		JE found
		
		CMP byte ptr [DI - 1], ','
		JE found
		
		CMP byte ptr [DI - 1], '!'
		JE found
		
		CMP byte ptr [DI - 1], '?'
		JE found
		
		CMP byte ptr [DI - 1], ':'
		JE found
		
		CMP byte ptr [DI - 1], ';'
		JE found
		
		CMP byte ptr [DI - 1], CR
		JE found
		
		JMP continue_find
		
	found:
	
		MOV DL, flag_achadas
		OR DL, DL
		JZ primeira_achadas
	
		LEA DX, achado_linha
		CALL prints
		
		XOR AX, AX
		MOV AX, linha
		CALL printn

		MOV DX, ':'
		CALL printc
		
		MOV DX, ' '
		CALL printc
		
		XOR BX, BX
		MOV BX, DI
		CALL get_context
		
		CMP byte ptr [DI - 1], CR
		JE end_find
		
		LEA SI, lido
		DEC DI
		JMP loop_tryfind
		
	primeira_achadas:
		INC DL
		MOV flag_achadas, DL
		LEA DX, prompt_encontradas
		CALL prints
		JMP found
	
	end_find:
	RET

find ENDP


; Recieves DI in the end of the word and prints the word in fornt and after if exists
get_context PROC FAR
	
	XOR AX, AX
	
	MOV AL, 3 ; Um arquivo legal
	
	CMP byte ptr [BX], CR
	JE found_space
	
	CMP byte ptr [BX], ';'
	JE found_space
	
	CMP byte ptr [BX], ' '
	JE found_space
	
	CMP byte ptr [BX], '.'
	JE found_space
	
	CMP byte ptr [BX], ','
	JE found_space
	
	CMP byte ptr [BX], '!'
	JE found_space
	
	CMP byte ptr [BX], '?'
	JE found_space
	
	CMP byte ptr [BX], ':'
	JE found_space
	
	CMP byte ptr [BX], ';'
	JE found_space

	go_back:
		
		DEC BX
		
		CMP byte ptr [BX], CR
		JE found_space
	
		CMP byte ptr [BX], ' '
		JE found_space
		
		CMP byte ptr [BX], 0
		JE first_word_case
		
		JMP go_back
	
	first_word_case:
		
		DEC AL
		OR AL, AL
		JZ print_word_before
		
		JMP print_viw
	
	found_space:
		DEC AL
		OR AL, AL
		JNZ go_back	
	
	print_word_before:
	
		INC BX
		
		MOV DL, byte ptr [BX]
		CALL printc
		
		CMP byte ptr [BX], ' '
		JNE print_word_before
		
	print_viw: ;Very Important Word
		
		INC BX
		
		CMP byte ptr [BX], CR
		JE fim_context
		
		MOV DL, byte ptr [BX]
		MOV upped, DL
		CALL upper_c 
		MOV DL, upped
		
		CALL printc
		
		CMP byte ptr [BX], ' '
		JNE print_viw
	
	print_word_after:
		
		INC BX
		
		CMP byte ptr [BX], ' '
		JE fim_context
		
		CMP byte ptr [BX], CR
		JE fim_context
		
		MOV DL, byte ptr [BX]
		CALL printc
		
		JMP print_word_after
	
	fim_context:
	
		LEA DX, endl
		CALL prints
		
		RET

get_context ENDP

end