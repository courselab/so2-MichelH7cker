/*
 *    SPDX-FileCopyrightText: 2024 MichelH7cker <michel.hecker@usp.br>
 *    SPDX-FileCopyrightText: 2024 Monaco F. J. <monaco@usp.br>
 *   
 *    SPDX-License-Identifier: GPL-3.0-or-later
 *
 *  This file is a derivative work from SYSeg (https://gitlab.com/monaco/syseg)
 *  and contains modifications carried out by the following author(s):
 *  MichelH7cker <michel.hecker@usp.br>
 *  ms-erik <erikmelges@usp.br>
 */

#ifndef KERNEL_H
#define KERNEL_H

#define FS_SIGNATURE "\xeb\xety"  /* File system signature.                   */
#define FS_SIGLEN 4               /* Signature length.                        */
#define BUFF_SIZE 64		      /* Max command length.  */
#define PROMPT "> "		          /* Command-line prompt. */

#define MAX_CYLINDERS 80
#define MAX_HEADS 2 
#define MAX_SECTORS 63
#define DIR_ENTRY_LEN 32
#define SECTOR_SIZE 512
#define FS_HEADER_ADDRESS   0x7c00 
#define DIR_BUFFER_ADDRESS  0x9000  

/* This is kernel's entry function, which is called by the bootloader
   as soon as it loads the kernel from the this image. */

void kmain(void);		

/* This is the command interpreter, which is invoked by the kernel as
   soon as the boot is complete. 
   
   Our tiny command-line parser is too simple: commands are ASCII single words
   with no command line arguments (no blanks). */


void shell();			/* Command interpreter. */


/* Built-in commands. */
void f_help();
void f_list();
void f_exec();
void f_quit();

// Structs 
struct fs_header_t {
    unsigned char  signature[FS_SIGLEN];    /* The file system signature.              */
    unsigned short total_number_of_sectors; /* Number of 512-byte disk blocks.         */
    unsigned short number_of_boot_sectors;  /* Sectors reserved for boot code.         */
    unsigned short number_of_file_entries;  /* Maximum number of files in the disk.    */
    unsigned short max_file_size;		    /* Maximum size of a file in blocks.       */
    unsigned int   unused_space;            /* Remaining space less than max_file_size.*/
} __attribute__((packed)) ;        /* Disable alignment to preserve offsets.  */

extern struct cmd_t
{
  char name[32];
  void (*funct)();
} cmds[];

#endif  /* KERNEL_H  */
