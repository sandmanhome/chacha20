// Copyright (c) 2016 Andreas Auernhammer. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// +build go1.7
// +build amd64, !gccgo, !appengine

#include "textflag.h"

DATA one<>+0x00(SB)/8, $0x0
DATA one<>+0x08(SB)/8, $0x0
DATA one<>+0x10(SB)/8, $0x1
DATA one<>+0x18(SB)/8, $0x0
GLOBL one<>(SB), (NOPTR+RODATA), $32

DATA two<>+0x00(SB)/8, $0x2
DATA two<>+0x08(SB)/8, $0x0
DATA two<>+0x10(SB)/8, $0x2
DATA two<>+0x18(SB)/8, $0x0
GLOBL two<>(SB), (NOPTR+RODATA), $32

DATA rol16<>+0x00(SB)/8, $0x0504070601000302
DATA rol16<>+0x08(SB)/8, $0x0D0C0F0E09080B0A
DATA rol16<>+0x10(SB)/8, $0x0504070601000302
DATA rol16<>+0x18(SB)/8, $0x0D0C0F0E09080B0A
GLOBL rol16<>(SB), (NOPTR+RODATA), $32

DATA rol8<>+0x00(SB)/8, $0x0605040702010003
DATA rol8<>+0x08(SB)/8, $0x0E0D0C0F0A09080B
DATA rol8<>+0x10(SB)/8, $0x0605040702010003
DATA rol8<>+0x18(SB)/8, $0x0E0D0C0F0A09080B
GLOBL rol8<>(SB), (NOPTR+RODATA), $32

#define ROTL(n, v, t) \
	VPSLLD $n, v, t; \
	VPSRLD $(32-n), v, v; \
	VPXOR v, t, v

#define ROTL_FAST(c, v) \
	VPSHUFB c, v, v

// VPSHUFD $-109 -> See github.com/golang/go/issues/16499
#define SHUFFLE_128(a, b, c) \
	VPSHUFD $0x39, a, a; \
	VPSHUFD $0x4E, b, b; \
	VPSHUFD $-109, c, c

#define SHUFFLE_256(a0, a1, b0, b1, c0, c1) \
	VPSHUFD $0x39, a0, a0; \
	VPSHUFD $0x39, a1, a1; \
	VPSHUFD $0x4E, b0, b0; \
	VPSHUFD $0x4E, b1, b1; \
	VPSHUFD $-109, c0, c0; \
	VPSHUFD $-109, c1, c1

#define SHUFFLE_512(a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3) \
	VPSHUFD $0x39, a0, a0; \
	VPSHUFD $0x39, a1, a1; \
	VPSHUFD $0x39, a2, a2; \
	VPSHUFD $0x39, a3, a3; \
	VPSHUFD $0x4E, b0, b0; \
	VPSHUFD $0x4E, b1, b1; \
	VPSHUFD $0x4E, b2, b2; \
	VPSHUFD $0x4E, b3, b3; \
	VPSHUFD $-109, c0, c0; \
	VPSHUFD $-109, c1, c1; \
	VPSHUFD $-109, c2, c2; \
	VPSHUFD $-109, c3, c3

#define HALF_ROUND_128(v0, v1, v2, v3, t, c16, c8) \
	VPADDD v0, v1, v0; \
	VPXOR v3, v0, v3; \
	ROTL_FAST(c16, v3); \
	VPADDD v2, v3, v2; \
	VPXOR v1, v2, v1; \
	ROTL(12, v1, t); \
	VPADDD v0, v1, v0; \
	VPXOR v3, v0, v3; \
	ROTL_FAST(c8, v3); \
	VPADDD v2, v3, v2; \
	VPXOR v1, v2, v1; \
	ROTL(7, v1, t)

#define HALF_ROUND_256(v0, v1, v2, v3, v4, v5, v6, v7, t, c16, c8) \
	VPADDD v0, v1, v0; \
	VPADDD v4, v5, v4; \
	VPXOR v3, v0, v3; \
	VPXOR v7, v4, v7; \
	ROTL_FAST(c16, v3); \
	ROTL_FAST(c16, v7); \
	VPADDD v2, v3, v2; \
	VPADDD v6, v7, v6; \
	VPXOR v1, v2, v1; \
	VPXOR v5, v6, v5; \
	ROTL(12, v1, t); \
	ROTL(12, v5, t); \
	VPADDD v0, v1, v0; \
	VPADDD v4, v5, v4; \
	VPXOR v3, v0, v3; \
	VPXOR v7, v4, v7; \
	ROTL_FAST(c8, v3); \
	ROTL_FAST(c8, v7); \
	VPADDD v2, v3, v2; \
	VPADDD v6, v7, v6; \
	VPXOR v1, v2, v1; \
	VPXOR v5, v6, v5; \
	ROTL(7, v1, t); \
	ROTL(7, v5, t)

#define HALF_ROUND_512(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, t, c16, c8) \
	VPADDD v0, v1, v0; \
	VPADDD v4, v5, v4; \
	VPADDD v8, v9, v8; \
	VPADDD v12, v13, v12; \
	VPXOR v3, v0, v3; \
	VPXOR v7, v4, v7; \
	VPXOR v11, v8, v11; \
	VPXOR v15, v12, v15; \
	ROTL_FAST(c16, v3); \
	ROTL_FAST(c16, v7); \
	ROTL_FAST(c16, v11); \
	ROTL_FAST(c16, v15); \
	VPADDD v2, v3, v2; \
	VPADDD v6, v7, v6; \
	VPADDD v10, v11, v10; \
	VPADDD v14, v15, v14; \
	VPXOR v1, v2, v1; \
	VPXOR v5, v6, v5; \
	VPXOR v9, v10, v9; \
	VPXOR v13, v14, v13; \
	VMOVDQA v12, t; \
	ROTL(12, v1, v12); \
	ROTL(12, v5, v12); \
	ROTL(12, v9, v12); \
	ROTL(12, v13, v12); \
	VMOVDQA t, v12; \
	VPADDD v0, v1, v0; \
	VPADDD v4, v5, v4; \
	VPADDD v8, v9, v8; \
	VPADDD v12, v13, v12; \
	VPXOR v3, v0, v3; \
	VPXOR v7, v4, v7; \
	VPXOR v11, v8, v11; \
	VPXOR v15, v12, v15; \
	ROTL_FAST(c8, v3); \
	ROTL_FAST(c8, v7); \
	ROTL_FAST(c8, v11); \
	ROTL_FAST(c8, v15); \
	VPADDD v2, v3, v2; \
	VPADDD v6, v7, v6; \
	VPADDD v10, v11, v10; \
	VPADDD v14, v15, v14; \
	VPXOR v1, v2, v1; \
	VPXOR v5, v6, v5; \
	VPXOR v9, v10, v9; \
	VPXOR v13, v14, v13; \
	VMOVDQA v12, t; \
	ROTL(7, v1, v12); \
	ROTL(7, v5, v12); \
	ROTL(7, v9, v12); \
	ROTL(7, v13, v12); \
	VMOVDQA t, v12

#define XOR_128(dst, src, off, v0, v1, v2, v3, t0) \
	VPERM2I128 $32, v1, v0, t0; \
	VPXOR (0+off)(src), t0, t0; \
	VMOVDQU t0, (0+off)(dst); \
	VPERM2I128 $32, v3, v2, t0; \
	VPXOR (32+off)(src), t0, t0; \
	VMOVDQU t0, (32+off)(dst); \
	VPERM2I128 $49, v1, v0, t0; \
	VPXOR (64+off)(src), t0, t0; \
	VMOVDQU t0, (64+off)(dst); \
	VPERM2I128 $49, v3, v2, t0; \
	VPXOR (96+off)(src), t0, t0; \
	VMOVDQU t0, (96+off)(dst)

// func xorBlocksAVX2(dst, src []byte, state *[64]byte, rounds int)
TEXT ·xorBlocksAVX2(SB),4,$0-64
	MOVQ state+48(FP), AX
	MOVQ dst_base+0(FP), CX
	MOVQ src_base+24(FP), BX
	MOVQ src_len+32(FP), DX
	MOVQ rounds+56(FP), BP
	ANDQ $0xFFFFFFFFFFFFFFC0, DX	// DX = len(src) - (len(src) % 64)
	
	VMOVDQU 0(AX), Y2
	VMOVDQU 32(AX), Y3
	VPERM2I128 $0x22, Y2, Y0, Y0
	VPERM2I128 $0x33, Y2, Y1, Y1
	VPERM2I128 $0x22, Y3, Y2, Y2
	VPERM2I128 $0x33, Y3, Y3, Y3
	VMOVDQU one<>(SB), Y4
	VPADDQ Y4, Y3, Y3
	VMOVDQU rol16<>(SB), Y4
	VMOVDQU rol8<>(SB), Y5
	VMOVDQU two<>(SB), Y6
	VMOVDQA Y6, Y15
	
	CMPQ DX, $512
	JB BYTES_BETWEEN_0_AND_511
	// 0(SP) = rotl16 | 32(SP) = rotl8 | 64(SP) = [0,2,0,2]
	MOVQ SP, SI
	ANDQ $0xFFFFFFFFFFFFFFE0, SP
	SUBQ $(32+256), SP
	VMOVDQA Y4, 0(SP)
	VMOVDQA Y5, 32(SP)
	VMOVDQA Y15, 64(SP)
	VMOVDQA Y0, 96(SP)
	VMOVDQA Y1, 128(SP)
	VMOVDQA Y2, 160(SP)
	BYTES_AT_LEAST_512:
		VMOVDQA Y3, 192(SP)
		VMOVDQA Y0, Y4
		VMOVDQA Y1, Y5
		VMOVDQA Y2, Y6
		VPADDQ Y3, Y15, Y7
		VMOVDQA Y0, Y8
		VMOVDQA Y1, Y9
		VMOVDQA Y2, Y10
		VPADDQ Y7, Y15, Y11
		VMOVDQA Y0, Y12
		VMOVDQA Y1, Y13
		VMOVDQA Y2, Y14
		VPADDQ Y11, Y15, Y15
		MOVQ BP, R9
		CHACHA_LOOP_512:
			HALF_ROUND_512(Y0, Y1, Y2, Y3, Y4, Y5, Y6, Y7, Y8, Y9, Y10, Y11, Y12, Y13, Y14, Y15, 224(SP), 0(SP), 32(SP))
			SHUFFLE_512(Y1, Y5, Y9, Y13, Y2, Y6, Y10, Y14, Y3, Y7, Y11, Y15)
			HALF_ROUND_512(Y0, Y1, Y2, Y3, Y4, Y5, Y6, Y7, Y8, Y9, Y10, Y11, Y12, Y13, Y14, Y15, 224(SP), 0(SP), 32(SP))
			SHUFFLE_512(Y3, Y7, Y11, Y15, Y2, Y6, Y10, Y14, Y1, Y5, Y9, Y13)
			SUBQ $2, R9
			JA CHACHA_LOOP_512
		VMOVDQA Y12, 224(SP)
		VPADDD 96(SP), Y0, Y0
		VPADDD 128(SP), Y1, Y1
		VPADDD 160(SP), Y2, Y2
		VPADDD 192(SP), Y3, Y3
		XOR_128(CX, BX, 0, Y0, Y1, Y2, Y3, Y12)
		VMOVDQA 96(SP), Y0
		VMOVDQA 128(SP), Y1
		VMOVDQA 160(SP), Y2
		VMOVDQA 192(SP), Y3
		VPADDQ 64(SP), Y3, Y3
		VPADDD Y0, Y4, Y4
		VPADDD Y1, Y5, Y5
		VPADDD Y2, Y6, Y6
		VPADDD Y3, Y7, Y7
		XOR_128(CX, BX, 128, Y4, Y5, Y6, Y7, Y12)
		VMOVDQA 64(SP), Y7
		VPADDQ Y3, Y7, Y3
		VPADDD Y0, Y8, Y8
		VPADDD Y1, Y9, Y9
		VPADDD Y2, Y10, Y10
		VPADDD Y3, Y11, Y11
		XOR_128(CX, BX, 256, Y8, Y9, Y10, Y11, Y12)
		VPADDQ Y3, Y7, Y3
		VPADDD 224(SP), Y0, Y12
		VPADDD Y1, Y13, Y13
		VPADDD Y2, Y14, Y14
		VPADDD Y3, Y15, Y15
		XOR_128(CX, BX, 384, Y12, Y13, Y14, Y15, Y8)
		VMOVDQA 64(SP), Y15
		VPADDD Y3, Y15, Y3
		LEAQ 512(BX), BX
		LEAQ 512(CX), CX
		SUBQ $512, DX
		CMPQ DX, $512
		JAE BYTES_AT_LEAST_512
	VMOVDQA 0(SP), Y4
	VMOVDQA 32(SP), Y5
	MOVQ SI, SP
	CMPQ DX, $0
	JEQ WRITE_EVEN_64_BLOCKS
	
BYTES_BETWEEN_0_AND_511:
	CMPQ DX, $256
	JB BYTES_BETWEEN_0_AND_255

	VMOVDQA Y0, Y6
	VMOVDQA Y1, Y7
	VMOVDQA Y2, Y8
	VMOVDQA Y3, Y9
	VMOVDQA Y0, Y10
	VMOVDQA Y1, Y11
	VMOVDQA Y2, Y12
	VPADDQ Y3, Y15, Y13
	MOVQ BP, R9
CHACHA_LOOP_256:
		HALF_ROUND_256(Y6, Y7, Y8, Y9, Y10, Y11, Y12, Y13, Y14, Y4, Y5)
		SHUFFLE_256(Y7, Y11, Y8, Y12, Y9, Y13)
		HALF_ROUND_256(Y6, Y7, Y8, Y9, Y10, Y11, Y12, Y13, Y14, Y4, Y5)
		SHUFFLE_256(Y9, Y13, Y8, Y12, Y7, Y11)
		SUBQ $2, R9
		JA CHACHA_LOOP_256
	VPADDD Y0, Y6, Y6
	VPADDD Y1, Y7, Y7
	VPADDD Y2, Y8, Y8
	VPADDD Y3, Y9, Y9
	XOR_128(CX, BX, 0, Y6, Y7, Y8, Y9, Y14)
	VPADDD Y3, Y15, Y3
	VPADDD Y0, Y10, Y10
	VPADDD Y1, Y11, Y11
	VPADDD Y2, Y12, Y12
	VPADDD Y3, Y13, Y13
	XOR_128(CX, BX, 128, Y10, Y11, Y12, Y13, Y14)
	VPADDD Y3, Y15, Y3
	LEAQ 256(BX), BX
	LEAQ 256(CX), CX
	SUBQ $256, DX
	JEQ WRITE_EVEN_64_BLOCKS

BYTES_BETWEEN_0_AND_255:
	VMOVDQA Y0, Y6
	VMOVDQA Y1, Y7
	VMOVDQA Y2, Y8
	VMOVDQA Y3, Y9
	MOVQ BP, R9
CHACHA_LOOP_128:
		HALF_ROUND_128(Y6, Y7, Y8, Y9, Y10, Y4, Y5)
		SHUFFLE_128(Y7, Y8, Y9)
		HALF_ROUND_128(Y6, Y7, Y8, Y9, Y10, Y4, Y5)
		SHUFFLE_128(Y9, Y8, Y7)
		SUBQ $2, R9
		JA CHACHA_LOOP_128
	VPADDD Y0, Y6, Y6
	VPADDD Y1, Y7, Y7
	VPADDD Y2, Y8, Y8
	VPADDD Y3, Y9, Y9
		
	VPERM2I128 $32, Y7, Y6, Y11
	VPERM2I128 $32, Y9, Y8, Y12
	VPXOR 0(BX), Y11, Y11
	VMOVDQU Y11, 0(CX)
	VPXOR 32(BX), Y12, Y12
	VMOVDQU Y12, 32(CX)
	SUBQ $64, DX
	JEQ WRITE_ODD_64_BLOCKS
		
	VPADDD Y3, Y15, Y3
	VPERM2I128 $49, Y7, Y6, Y11
	VPERM2I128 $49, Y9, Y8, Y12
	VPXOR 64(BX), Y11, Y11
	VMOVDQU Y11, 64(CX)
	VPXOR 96(BX), Y12, Y12
	VMOVDQU Y12, 96(CX)
	SUBQ $64, DX
	JEQ WRITE_EVEN_64_BLOCKS
		
	LEAQ 128(BX), BX
	LEAQ 128(CX), CX
	JMP BYTES_BETWEEN_0_AND_255
WRITE_ODD_64_BLOCKS:
	VPERM2I128 $1, Y3, Y3, Y3
WRITE_EVEN_64_BLOCKS:
	VZEROUPPER
	MOVO X3, 48(AX)
	RET

// func supportAVX2() bool
TEXT ·supportAVX2(SB),4,$0-1
	XORQ AX, AX
	MOVQ runtime·support_avx2(SB), AX
	MOVB AX, ret+0(FP)
	RET
