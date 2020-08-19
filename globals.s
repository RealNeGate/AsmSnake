.data
TITLE_TEMP: .fill 64, 1, 0
GAME_OVER_TEXT: .ascii "GAME OVER\0"
MSG2_EVT: .ascii "EVENT 2\n\0"
MSG_EVT: .ascii "EVENT\n\0"
PANIC_MSG: .ascii "PANIC!!!\0"
TITLE: .ascii "Snake\0"
TITLE_FMT: .ascii "Snake - Score: %d\0"
TITLE_GAME_OVER_FMT: .ascii "Snake - GAME OVER - Score: %d\0"
CLASSNAME: .ascii "SNK\0"
FRUIT_X: .quad 0
FRUIT_Y: .quad 0
GAME_OVER: .byte 0
SNAKE_DIR: .byte 0
SNAKE_LAST_DIR: .quad 0
SNAKE_LEN: .quad 0
SNAKE_POS: .fill 325, 8, 0
PIXELS: .quad 0
IS_RUNNING: .quad 0
TIMER_CURR: .quad 0
TIMER_START: .quad 0
TIMER_FREQ: .quad 0
FLOAT_ZERO: .quad 0
FLOAT_ONE:
	.long 0 
	.long 1072693248
FLOAT_ONE_OVER_FRAMETIME: //; double(1.0 / 6.0)
    .long 1431655765
    .long 1069897045
BMP:
	biSize: 			.long 0
	biWidth: 			.long 0
	biHeight: 			.long 0
	biPlanes: 			.value 0
	biBitCount: 		.value 0
	biCompression: 		.long 0
	biSizeImage: 		.long 0
	biXPelsPerMeter: 	.long 0
	biYPelsPerMeter: 	.long 0
	biClrUsed: 			.long 0
	biClrImportant: 	.long 0
	rgbBlue: 			.byte 0
	rgbGreen: 			.byte 0
	rgbRed: 			.byte 0
	rgbReserved: 		.byte 0
