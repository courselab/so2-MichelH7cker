/*
 *    SPDX-FileCopyrightText: 2024 ms-erik <erikmelges@usp.br>
 *   
 *    SPDX-License-Identifier: GPL-3.0-or-later
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define MOV_AL 0xB0
#define MOV_AH 0xB4
#define JMP 0xEB
#define HALT 0xF4
#define INT 0xCD
#define EMPTY 0x00
#define DELIMITER " \t\n,%"
#define SIGNATURE 0x55, 0xAA

void assembler_n_linker(FILE *input_file, FILE *output_file){
    char *parameter;
    char line[256];
    while(fgets(line,sizeof(line),input_file)){

        parameter = strtok(line,DELIMITER);
        while(parameter != NULL){
            
            if(!strcmp(parameter,"mov")){
                parameter = strtok(NULL, DELIMITER);
                parameter = parameter + 1;
                unsigned char value = (unsigned char) strtol(parameter, NULL, 16);
                parameter = strtok(NULL,DELIMITER);
                if(!strcmp(parameter, "ah")){
                    fputc(MOV_AH, output_file);
                }else{
                    fputc(MOV_AL,output_file);
                }
                fputc(value,output_file);
            }
            if(!strcmp(parameter, "jmp")){
                fputc(JMP,output_file);
            }
            if(!strcmp(parameter, "hlt")){
                fputc(HALT,output_file);
            }
            if(!strcmp(parameter, "int")){
                parameter = strtok(NULL, DELIMITER);
                parameter = parameter +1;
                unsigned char value = (unsigned char) strtol(parameter,NULL,16);
                fputc(INT,output_file);
                fputc(value, output_file);
            }
            if(!strcmp(parameter,"halt")){
                fputc(0xFD,output_file);
            }

            parameter = strtok(NULL,DELIMITER);
        }
    }

    int curr = ftell(output_file);
    for(; curr < 510; curr++){
        fputc(0,output_file);
    }

    unsigned char sig[] = {SIGNATURE};
    fwrite(sig, sizeof(sig),1, output_file);

    fclose(input_file);
    fclose(output_file);

}

int main(int argc, char *argv[]){
    FILE *input_file;
    input_file = fopen(argv[1],"r");
    if(!input_file){
        exit(EXIT_FAILURE);
    }
    FILE *output_file;
    output_file = fopen(argv[2],"wb");
    if(!output_file){
        fclose(input_file);
        exit(EXIT_FAILURE);
    }
    assembler_n_linker(input_file, output_file);
    return 0;
}
