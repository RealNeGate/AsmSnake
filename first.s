//; NOTE: I'm sorry, not very good at this...
//; Comment
.extern MessageBoxA
.extern GetModuleHandleA
.extern RegisterClassExA
.extern ExitProcess
.extern CreateWindowExA
.extern GetMessageA
.extern PeekMessageA
.extern TranslateMessage
.extern DispatchMessageA
.extern PostQuitMessage
.extern OutputDebugStringA
.extern GetProcessHeap
.extern HeapAlloc
.extern HeapFree
.extern GetDC
.extern SetDCBrushColor
.extern SetDCPenColor
.extern UpdateWindow
.extern Rectangle
.extern QueryPerformanceFrequency
.extern QueryPerformanceCounter
.extern GetStdHandle
.extern WriteFile
.extern TextOutA
.extern SetWindowTextA
.extern wsprintfA
.set WINDOW_WIDTH, 900 + 16
.set WINDOW_HEIGHT, 900 + 39

.set SCREEN_WIDTH, 900
.set SCREEN_HEIGHT, 900
.set SCREEN_PIXELS, SCREEN_WIDTH * SCREEN_HEIGHT
.set SCREEN_BYTES, SCREEN_PIXELS * 4
.set SCREEN_STRIDE, 3600
.set SNAKE_MAX, 50
.set TILE, 50

.set MAP_WIDTH, SCREEN_WIDTH / TILE
.set MAP_HEIGHT, SCREEN_HEIGHT / TILE

.set INPUT_UP, 0
.set INPUT_DOWN, 1
.set INPUT_LEFT, 2
.set INPUT_RIGHT, 3

.global entry
.global WndProc
.global Game_FillRect
.global Game_GetTime
.global Game_LogNumber
.global Game_LogString
.global Game_RandomNumber
.global Game_Startup

.include "globals.s"

.text
Game_Startup:
	//; GAME_OVER = 1
	movb $0, GAME_OVER(%rip)
	//; FRUIT_X = 5
	//; FRUIT_Y = 3
	movl $5, FRUIT_X(%rip)
	movl $8, FRUIT_Y(%rip)
	//; SNAKE_DIR = INPUT_LEFT
	movb $INPUT_LEFT, SNAKE_DIR(%rip)
	movb $INPUT_LEFT, SNAKE_LAST_DIR(%rip)
	//; SNAKE_LEN = 3
	movq $3, SNAKE_LEN(%rip)
	lea SNAKE_POS(%rip), %rcx
	//; SNAKE_POS[0] = 8
	//; SNAKE_POS[1] = 8
	movl $8, 0(%rcx)
	movl $8, 4(%rcx)
	//; SNAKE_POS[2] = 9
	//; SNAKE_POS[3] = 8
	movl $9, 8(%rcx)
	movl $8, 12(%rcx)
	//; SNAKE_POS[4] = 10
	//; SNAKE_POS[5] = 8
	movl $10, 16(%rcx)
	movl $8, 20(%rcx)
	ret

WndProc:
	//; if (msg == 16) {
	cmp $16, %edx
	je WndProc_case_close
	cmp $256, %edx
	je WndProc_case_key
	cmp $257, %edx
	je WndProc_case_key
	cmp $260, %edx
	je WndProc_case_key
	cmp $261, %edx
	je WndProc_case_key
	jmp WndProc_case_default
	//; case WM_KEYUP WM_KEYDOWN WM_SYSKEYUP WM_SYSKEYDOWN
	WndProc_case_key:
		//; Extract virtual key
		mov %r8, %rax
		and $0xFFFF, %eax
		//; NOTE: There's better ways to do this
		//; UP
		cmp $0x26, %eax
		je WndProc_case_key_up
		cmp $87, %eax
		je WndProc_case_key_up
		//; DOWN
		cmp $0x28, %eax
		je WndProc_case_key_down
		cmp $83, %eax
		je WndProc_case_key_down
		//; LEFT
		cmp $0x25, %eax
		je WndProc_case_key_left
		cmp $65, %eax
		je WndProc_case_key_left
		//; RIGHT
		cmp $0x27, %eax
		je WndProc_case_key_right
		cmp $68, %eax
		je WndProc_case_key_right
		//; ENTER
		cmp $0x0D, %eax
		je WndProc_case_key_enter
		//; DEFAULT
		jmp WndProc_case_break
		WndProc_case_key_up:
			//; if (SNAKE_LAST_DIR != INPUT_DOWN) SNAKE_DIR = INPUT_UP
			mov $INPUT_UP, %dl
			mov SNAKE_DIR(%rip), %cl
			cmpb $INPUT_DOWN, SNAKE_LAST_DIR(%rip)
			cmovne %dx, %cx
			mov %cl, SNAKE_DIR(%rip)
			jmp WndProc_case_break
		WndProc_case_key_down:
			//; if (SNAKE_LAST_DIR != INPUT_UP) SNAKE_DIR = INPUT_DOWN
			mov $INPUT_DOWN, %dl
			mov SNAKE_DIR(%rip), %cl
			cmpb $INPUT_UP, SNAKE_LAST_DIR(%rip)
			cmovne %dx, %cx
			mov %cl, SNAKE_DIR(%rip)
			jmp WndProc_case_break
		WndProc_case_key_left:
			//; if (SNAKE_LAST_DIR != INPUT_RIGHT) SNAKE_DIR = INPUT_LEFT
			mov $INPUT_LEFT, %dl
			mov SNAKE_DIR(%rip), %cl
			cmpb $INPUT_RIGHT, SNAKE_LAST_DIR(%rip)
			cmovne %dx, %cx
			mov %cl, SNAKE_DIR(%rip)
			jmp WndProc_case_break
		WndProc_case_key_right:
			//; if (SNAKE_LAST_DIR != INPUT_LEFT) SNAKE_DIR = INPUT_RIGHT
			mov $INPUT_RIGHT, %dl
			mov SNAKE_DIR(%rip), %cl
			cmpb $INPUT_LEFT, SNAKE_LAST_DIR(%rip)
			cmovne %dx, %cx
			mov %cl, SNAKE_DIR(%rip)
			jmp WndProc_case_break
		WndProc_case_key_enter:
			cmpb $0, GAME_OVER(%rip)
			je Game_actually_restart_end
			call Game_Startup
			Game_actually_restart_end:
			jmp WndProc_case_break
		WndProc_case_break:
		//; return 0;
		xor %eax, %eax
		ret
	WndProc_case_close:
		//; ExitProcess(0);
		movq $0, IS_RUNNING(%rip)
		//; return 0;
		xor %eax, %eax
		ret
	//; }
	//; return DefWindowProcA(...)
	WndProc_case_default:
	jmp DefWindowProcA

//; rax - color
//; rcx - x
//; rdx - y
//; r8 - w
//; r9 - h
Game_FillRect:
	//; PIXELS + ((x + (y * SCREEN_WIDTH)) * 4)
	//; Save color 
	imul $SCREEN_WIDTH, %rdx, %r11
	add %rcx, %r11
	mov PIXELS(%rip), %r10
	lea (%r10, %r11, 4), %r10
	Game_FillScanline:
	//; Check if done
	cmp $0, %r9
	je Game_FillScanline_exit
	//; Fill scanline
	mov %r8, %rcx
	movq %r10, %rdi
	rep stosl
	//; Next line is (screen_width * 4) away
	add $SCREEN_STRIDE, %r10
	dec %r9
	jmp Game_FillScanline
	Game_FillScanline_exit:
	xor %rax, %rax
	ret

Game_GetTime:
	sub $32, %rsp
	lea TIMER_CURR(%rip), %rcx
	call QueryPerformanceCounter
	mov TIMER_CURR(%rip), %rax
	sub TIMER_START(%rip), %rax
	cvtsi2sd %eax, %xmm1
	movsd   TIMER_FREQ(%rip), %xmm0
	mulsd   %xmm1, %xmm0
	add $32, %rsp
	ret

Game_RandomNumber:
	rdtsc
	mov %edx, %ecx
	shl $32, %rcx
	or %rax, %rcx
	mov %rcx, %rax
	ret

Game_LogString:
	jmp OutputDebugStringA
Game_LogNumber:
	//; Call usage: 32
	//; Locals: 16 (8 + 8 align)
	//; Align: 8
	//; = 56
	sub $56, %rsp
	mov $48, %al
	add %cl, %al
	movb %al, 32(%rsp)
	movb $10, 33(%rsp)
	movb $0, 34(%rsp)
	lea 32(%rsp), %rcx
	call OutputDebugStringA
	add $56, %rsp
	ret

entry:
	//; Call usage: 96
	//; Locals: 160 (152 + 8 align)
	//; Align: 8
	//; = 264
	sub $264, %rsp

	//; hInstance 		: 8 = GetModuleHandleA(null)
	xor %ecx, %ecx
	call GetModuleHandleA
	movq %rax, 96(%rsp)

	//; wc := { 0 };
	//; wc.cbSize		: 4 = 80;
	movl $80, 104(%rsp)
	//; wc.style		: 4 = 35;
	movl $35, 108(%rsp)
	//; wc.lpfnWndProc	: 8 = WndProc;
	lea WndProc(%rip), %rax
	movq %rax, 112(%rsp)
	//; wc.cbClsExtra	: 4 = 0;
	//; wc.cbWndExtra	: 4 = 0;
	xor %eax, %eax
	movq %rax, 120(%rsp)
	//; wc.hInstance	: 8 = hInstance;
	movq 32(%rsp), %rax
	movq %rax, 128(%rsp)
	//; wc.hIcon		: 8 = 0;
	//; wc.hCursor		: 8 = 0;
	//; wc.hbrBackgroun	: 8 = 0;
	//; wc.lpszMenuName	: 8 = 0;
	xor %eax, %eax
	movq %rax, 136(%rsp)
	movq %rax, 144(%rsp)
	movq %rax, 152(%rsp)
	movq %rax, 160(%rsp)
	//; wc.lpszClassName: 8 = 0;
	lea CLASSNAME(%rip), %rax
	movq %rax, 168(%rsp)
	//; wc.hIconSm		: 8 = 0;
	xor %eax, %eax
	movq %rax, 176(%rsp)
	//; if (RegisterClassExA(@wc) == 0) panic();
	lea 104(%rsp), %rcx
	call RegisterClassExA
	cmpq $0, %rax
	jne RegisterClass_post_branch
	int $3
	RegisterClass_post_branch:
	//; wnd				: 8 = CreateWindowExA(...)
	mov $262144,		%rcx
	lea CLASSNAME(%rip),%rdx
	lea TITLE(%rip), 	%r8
	movq $0x100A0000, 	%r9
	movl $2147483648, 	%eax
	movq %rax, 			32(%rsp)
	movq %rax, 			40(%rsp)
	movq $WINDOW_WIDTH,	48(%rsp)
	movq $WINDOW_HEIGHT,56(%rsp)
	xor %eax, %eax
	movq %rax, 			64(%rsp)
	movq %rax, 			72(%rsp)
	movq 96(%rsp), %rax
	movq %rax, 			80(%rsp)
	xor %eax, %eax
	movq %rax, 			88(%rsp)
	call CreateWindowExA
	//; if (wnd == 0) panic();
	cmpq $0, %rax
	jne CreateWindow_post_branch
	int $3
	CreateWindow_post_branch:
	mov %rax, 184(%rsp)
	//; ShowWindow(wnd, 5)
	mov %rax, %rcx
	mov $5, %rdx
	call ShowWindow
	//; SetFocus(wnd)
	mov 184(%rsp), %rcx
	call SetFocus
	//; msg 			: 48 = { 0 }
	lea 192(%rsp), %rcx
	xor %rax, %rax
	movq %rax, (%rcx)
	movq %rax, 8(%rcx)
	movq %rax, 16(%rcx)
	movq %rax, 24(%rcx)
	movq %rax, 32(%rcx)
	movq %rax, 40(%rcx)
	//; Game_Startup()
	call Game_Startup
	//; IS_RUNNING = 1;
	movq $1, IS_RUNNING(%rip)
	//; sHeap			: 8 = GetProcessHeap();
	call GetProcessHeap
	movq %rax, 240(%rsp)
	//; PIXELS			: 8 = HeapAlloc(sHeap, 8, SCREEN_BYTES);
	mov %rax, %rcx
	mov $8, %edx
	mov $SCREEN_BYTES, %r8
	call HeapAlloc
	movq %rax, PIXELS(%rip)
	//; NOTE: Initialize bitmap info
	movl $44, biSize(%rip)
	movl $SCREEN_WIDTH, biWidth(%rip)
	movl $SCREEN_HEIGHT, biHeight(%rip)
	movb $1, biPlanes(%rip)
	movb $32, biBitCount(%rip)
	movl $0, biCompression(%rip)
	//; QueryPerformanceFrequency(@TIMER_FREQ)
	lea TIMER_FREQ(%rip), %rcx
	call QueryPerformanceFrequency
	movq TIMER_FREQ(%rip), %rax
	//; TIMER_FREQ.f64	: 8 = 1.0 / TIMER_FREQ.int32
	//; TODO: FIXME: THIS IS VERY DANGEROUS
	cvtsi2sd %eax, %xmm1
	movsd FLOAT_ONE(%rip), %xmm0
	divsd %xmm1, %xmm0
	movsd %xmm0, TIMER_FREQ(%rip)
	//; QueryPerformanceCounter(@TIMER_START)
	lea TIMER_START(%rip), %rcx
	call QueryPerformanceCounter
	//; last_time		: 8 = Game_GetTime();
	call Game_GetTime
	movsd %xmm0, %xmm6
	//; frame_time		: 8 = 1.0;
	movsd FLOAT_ONE_OVER_FRAMETIME(%rip), %xmm7
	//; elapsed_time	: 8 = 0.0;
	movsd FLOAT_ZERO(%rip), %xmm8
	//; while (IS_RUNNING) {
	while_is_running:
		//;	while (GetMessageA(&message, NULL, NULL, NULL)) {
		while_peek_msg:
			cmpq $0, IS_RUNNING(%rip)
			je while_is_running_exit
			lea 192(%rsp), %rcx
			xor %rdx, %rdx
			xor %r8, %r8
			xor %r9, %r9
			movq $1, 32(%rsp)
			call PeekMessageA
			test %eax, %eax
			jle while_peek_msg_exit
			//;	TranslateMessage(&message);
			lea 192(%rsp), %rcx
			call TranslateMessage
			//;	DispatchMessageA(&message);
			lea 192(%rsp), %rcx
			call DispatchMessageA
			//; }
			jmp while_peek_msg
		while_peek_msg_exit:
		//; NOTE: Timing
		//; current_time	: 8 = Game_GetTime()
		call Game_GetTime
		//; elapsed_time += current_time - last_time
		movsd %xmm0, %xmm1
		subsd %xmm6, %xmm1
		addsd %xmm1, %xmm8
		//; last_time = current_time
		movsd %xmm0, %xmm6
		//; while (elapsed_time >= 1.0 && !GAME_OVER) {
		Game_Tick:
			comisd %xmm8, %xmm7
			ja Game_Tick_exit
			cmpb $0, GAME_OVER(%rip)
			jne Game_Tick_game_over_exit
			//; NOTE: Update Game State
			//; NOTE: Reserve first slot for new body part
			lea SNAKE_POS(%rip), %rdx
			mov SNAKE_LEN(%rip), %r14
			Game_Tick_Reserve:
				cmp $0, %r14
				je Game_Tick_Reserve_exit
				dec %r14
				//; r15 := SNAKE_POS + (%r14 * 2 * sizeof(int))
				lea SNAKE_POS(%rip), %rdx
				lea (%rdx, %r14, 8), %r15
				//; NOTE: Shift over
				movq (%r15), %rax
				movq %rax, 8(%r15)
				//; }
				jmp Game_Tick_Reserve
			Game_Tick_Reserve_exit:

			lea SNAKE_POS(%rip), %rdx
			movl 0(%rdx), %r8d
			movl 4(%rdx), %r9d
			//; NOTE: Move body based on SNAKE_DIR
			//; NOTE: TODO: Use a jump table
			movb SNAKE_DIR(%rip), %r11b
			movb %r11b, SNAKE_LAST_DIR(%rip)

			cmp $INPUT_UP, %r11b
			je Input_case_up
			cmp $INPUT_DOWN, %r11b
			je Input_case_down
			cmp $INPUT_LEFT, %r11b
			je Input_case_left
			cmp $INPUT_RIGHT, %r11b
			je Input_case_right
			//; INVALID SNAKE DIRECTION
			int $3
			Input_case_up:
				//; head_y++
				inc %r9d
				jmp Input_case_break
			Input_case_down:
				dec %r9d
				jmp Input_case_break
			Input_case_left:
				//; head_x--
				dec %r8d
				jmp Input_case_break
			Input_case_right:
				//; head_x++
				inc %r8d
				//; break;
			jmp Input_case_break
			Input_case_break:
			Game_Physics_tick:
				//; NOTE: Check collisions with the head and the fruit
				//; if (FRUIT_X == head_x && FRUIT_Y == head_y) {
				cmp FRUIT_X(%rip), %r8d
				jne Game_Physics_touch_fruit_exit
				cmp FRUIT_Y(%rip), %r9d
				jne Game_Physics_touch_fruit_exit
				Game_Physics_touch_fruit:
					//; Add new piece to the body
					incq SNAKE_LEN(%rip)

					Game_Physics_respawn_fruit:
						//; Game_RandomNumber() % MAP_WIDTH
						call Game_RandomNumber
						mov $MAP_WIDTH, %edi
						xor %rdx, %rdx
						divq %rdi
						//; NOTE: Its unsigned, this casting is fine
						//; NOTE: unsigned 64bit -> unsigned 32bit
						mov %edx, %r10d
						//; Game_RandomNumber() % MAP_HEIGHT
						call Game_RandomNumber
						mov $MAP_HEIGHT, %edi
						xor %rdx, %rdx
						divq %rdi
						//; NOTE: Its unsigned, this casting is fine
						//; NOTE: unsigned 64bit -> unsigned 32bit
						mov %edx, %r11d
						//; counter : %r14 = SNAKE_LEN
						mov SNAKE_LEN(%rip), %r14

						//; if (HEAD_X == FRUIT_X && HEAD_Y == FRUIT_Y) 
						//;		goto Game_Physics_respawn_fruit;
						cmp %r8d, %r10d
						jne Game_Physics_collide_body_fruit
						cmp %r9d, %r11d
						jne Game_Physics_collide_body_fruit
						jmp Game_Physics_respawn_fruit

						//; while (counter-- > 0) {
						Game_Physics_collide_body_fruit:
							cmp $0, %r14
							je Game_Physics_collide_body_fruit_exit
							dec %r14
							//; r15 := SNAKE_POS + (%r14 * 2 * sizeof(int))
							lea SNAKE_POS(%rip), %rdx
							lea (%rdx, %r14, 8), %r15

							cmp 0(%r15), %r10d
							jne Game_Physics_collide_body_fruit
							cmp 4(%r15), %r11d
							jne Game_Physics_collide_body_fruit
							jmp Game_Physics_respawn_fruit
						//; }
						Game_Physics_collide_body_fruit_exit:
						
						movq %r10, FRUIT_X(%rip)
						movq %r11, FRUIT_Y(%rip)
				//; }
				Game_Physics_touch_fruit_exit:
				//; NOTE: Check collisions with other pieces
				cmp $MAP_WIDTH, %r8d
				jae Game_Physics_out_of_bounds
				cmp $MAP_HEIGHT, %r9d
				jae Game_Physics_out_of_bounds
				jmp Game_Physics_in_bounds
				Game_Physics_out_of_bounds:
					//; GAME_OVER = 1
					movb $1, GAME_OVER(%rip)
					//; Retitle the window
					lea TITLE_TEMP(%rip), %rcx
					lea TITLE_GAME_OVER_FMT(%rip), %rdx
					mov SNAKE_LEN(%rip), %r8
					call wsprintfA
					mov 184(%rsp), %rcx
					lea TITLE_TEMP(%rip), %rdx
					call SetWindowTextA
					jmp Game_Tick_game_over_exit
				Game_Physics_in_bounds:
					//; NOTE: Store position
					//; counter : %r14 = SNAKE_LEN
					mov SNAKE_LEN(%rip), %r14
					//; while (counter-- > 0) {
					Game_Physics_collide_body_head:
						cmp $0, %r14
						je Game_Physics_collide_body_head_exit
						dec %r14
						
						//; r15 := SNAKE_POS + (%r14 * 2 * sizeof(int))
						lea SNAKE_POS(%rip), %rdx
						lea (%rdx, %r14, 8), %r15
						//; if (x == body[counter].x && y == body[counter]) 
						//;		goto Game_Physics_in_bounds;
						cmp 0(%r15), %r8d
						jne Game_Physics_collide_body_head
						cmp 4(%r15), %r9d
						jne Game_Physics_collide_body_head

						jmp Game_Physics_out_of_bounds
					Game_Physics_collide_body_head_exit:

					lea SNAKE_POS(%rip), %rdx
					movl %r8d, 0(%rdx)
					movl %r9d, 4(%rdx)
					//;jmp Game_Physics_tick_end
			Game_Physics_tick_end:
			//; Retitle the window
			lea TITLE_TEMP(%rip), %rcx
			lea TITLE_FMT(%rip), %rdx
			mov SNAKE_LEN(%rip), %r8
			call wsprintfA
			mov 184(%rsp), %rcx
			lea TITLE_TEMP(%rip), %rdx
			call SetWindowTextA
			//; elapsed_time -= 1.0
			subsd %xmm7, %xmm8
			//; }
			jmp Game_Tick
		Game_Tick_game_over_exit:
			//; last_time = Game_GetTime();
			call Game_GetTime
			movsd %xmm0, %xmm6
			//; frame_time = 1.0;
			movsd FLOAT_ONE_OVER_FRAMETIME(%rip), %xmm7
			//; elapsed_time = 0.0;
			movsd FLOAT_ZERO(%rip), %xmm8
		Game_Tick_exit:
		//; NOTE: Clear screen
		xor %eax, %eax
		movl $SCREEN_PIXELS, %ecx
		movq PIXELS(%rip), %rdi
		rep stosl
		//; NOTE: Draw fruit
		mov $TILE, %rax
		mov FRUIT_X(%rip), 	%rcx
		imul $TILE, %rcx
		mov FRUIT_Y(%rip),	%rdx
		imul $TILE, %rdx
		mov $TILE,	%r8
		mov $TILE,	%r9
		mov $0xFF0000, %eax
		call Game_FillRect
		//; NOTE: Draw snake
		//; %r14 := counter
		//; while (%r14-- > SNAKE_LEN) {
		mov SNAKE_LEN(%rip), %r14
		Snake_Draw:
			cmp $0, %r14
			je Snake_Draw_exit
			dec %r14
			//; NOTE: Draw snake body square
			//; r15 := SNAKE_POS + (%r14 * 2 * sizeof(int))
			lea SNAKE_POS(%rip), %rdx
			lea (%rdx, %r14, 8), %r15
			//; Game_FillRect(r15->x * TILE, r15->y * TILE, TILE, TILE)
			mov $TILE, %rax
			mov 0(%r15), 	%ecx
			imul $TILE, %rcx
			add $8, %rcx
			mov 4(%r15),	%edx
			imul $TILE, %rdx
			add $8, %rdx
			mov $TILE,		%r8
			sub $16, %r8
			mov $TILE,		%r9
			sub $16, %r9
			mov $0xFFFFFF, %eax
			call Game_FillRect
			//; }
			jmp Snake_Draw
		Snake_Draw_exit:
		//; NOTE: Draw Bitmap
		movq 184(%rsp), %rcx
		call GetDC
		mov %rax, 			%rcx
		xor %rdx,			%rdx
		xor %r8,			%r8
		movq $SCREEN_WIDTH,	%r9
		movq $SCREEN_HEIGHT,%rax
		movq %rax, 			32(%rsp)
		movq $0, 			40(%rsp)
		movq $0,			48(%rsp)
		movq $SCREEN_WIDTH,%rax
		movq %rax, 			56(%rsp)
		movq $SCREEN_HEIGHT,%rax
		movq %rax, 			64(%rsp)
		movq PIXELS(%rip), %rax
		movq %rax, 			72(%rsp)
		lea BMP(%rip), %rax
		movq %rax, 			80(%rsp)
		movq $0,			88(%rsp)
		movq $13369376,		96(%rsp)
		call StretchDIBits
		//; if (GAME_OVER) {
		cmpb $0, GAME_OVER(%rip)
		je Game_Over_View_exit
		//; TextOutA(GetDC(wnd), 0, 0, GAME_OVER_TEXT, strlen(GAME_OVER_TEXT));
		movq 184(%rsp), %rcx
		call GetDC
		movq %rax, 		%rcx
		movq $0,		%rdx
		movq $0,		%r8
		lea GAME_OVER_TEXT(%rip), %r9
		//; NOTE: This '9' isn't robust, its based on
		//; the length of GAME_OVER_TEXT
		movq $9,		32(%rsp)
		call TextOutA
		//; }
		Game_Over_View_exit:

		//; UpdateWindow(wnd);
		movq 184(%rsp), %rcx
		call UpdateWindow

		jmp while_is_running
	while_is_running_exit:
	//; HeapFree(sHeap, 0, PIXELS)
	movq 240(%rsp), %rcx
	xor %rdx, %rdx
	movq PIXELS(%rip), %r8
	call HeapFree
	//; ExitProcess(0)
	xor %ecx, %ecx
	call ExitProcess
	//; return 0
	xor %eax, %eax
	add $264, %rsp
	ret

