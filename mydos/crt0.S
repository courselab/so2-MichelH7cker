#    SPDX-FileCopyrightText: 2021 Monaco F. J. <monaco@usp.br>
#    SPDX-FileCopyrightText: 2024 MichelH7cker <michel.hecker@usp.br>
#
#    SPDX-License-Identifier: GPL-3.0-or-later
#
#  This file is a derivative work from SYSeg (https://gitlab.com/monaco/syseg)
#  and contains modifications carried out by the following author(s):
#  MichelH7cker <michel.hecker@usp.br>
#  ms-erik <erikmelges@usp.br>

	.code16gcc		/* Select 16-bit code.                    */
	.global _start		/* This will be the program entry point.  */
	.text

	jmp _start
_start:
  call main
	ret
