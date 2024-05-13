/*
 *    SPDX-FileCopyrightText: 2021 Monaco F. J. <monaco@usp.br>
 *    SPDX-FileCopyrightText: 2024 MichelH7cker <michel.hecker@usp.br>
 *   
 *    SPDX-License-Identifier: GPL-3.0-or-later
 *
 *  This file is a derivative work from SYSeg (https://gitlab.com/monaco/syseg)
 *  and contains modifications carried out by the following author(s):
 *  MichelH7cker <michel.hecker@usp.br>
 */

#include "bios.h"
#include "utils.h"

#define PROMPT "$ "		/* Prompt sign.      */
#define SIZE 20			/* Read buffer size. */

char buffer[SIZE];		/* Read buffer.      */
char buffer_dest[SIZE];		/* Read buffer.      */

int main(){
    clear();
   
    println  ("Boot Command 1.0");
    
    while (1) {
        print(PROMPT);		/* Show prompt.               */
        readln(buffer);		/* Read use input.            */

        if (buffer[0]){		/* Execute built-in command.  */
            strcpy(buffer_dest, buffer); 
            println(buffer_dest);
        }
    }

    return 0;

}

