/*uint8_t
 *    SPDX-FileCopyrightText: 2021 Monaco F. J. <monaco@usp.br>
 *    SPDX-FileCopyrightText: 2024 MichelH7cker <michel.hecker@usp.br>
 *   
 *    SPDX-License-Identifier: GPL-3.0-or-later
 *
 *  This file is a derivative work from SYSeg (https://gitlab.com/monaco/syseg)
 *  and contains modifications carried out by the following author(s):
 *  MichelH7cker <michel.hecker@usp.br>
 *  ms-erik <erikmelges@usp.br>
 */

/* This source file implements the kernel entry function 'kmain' called
   by the bootloader, and the command-line interpreter. Other kernel functions
   were implemented separately in another source file for legibility. */

#include "bios1.h"		/* For kwrite() etc.            */
#include "bios2.h"		/* For kread() etc.             */
#include "kernel.h"		/* Essential kernel functions.  */
#include "kaux.h"		/* Auxiliary kernel functions.  */
#include "tydos.h"
/* Kernel's entry function. */

void kmain(void)
{
  
  register_syscall_handler();	/* Register syscall handler at int 0x21.*/

  splash();			/* Uncessary spash screen.              */

  shell();			/* Invoke the command-line interpreter. */
  
  halt();			/* On exit, halt.                       */
  
}

/* Tiny Shell (command-line interpreter). */

char buffer[BUFF_SIZE];
int go_on = 1;

void shell()
{
  int i;
  clear();
  kwrite ("hacker_DOS 1.0\n");

  while (go_on){

      /* Read the user input. 
         Commands are single-word ASCII tokens with no blanks. */
      do {
          kwrite(PROMPT);
          kread (buffer);
      }
      while (!buffer[0]);

      /* Check for matching built-in commands */

      i=0;
      while (cmds[i].funct) {
          if (!strcmp(buffer, cmds[i].name)) {
              cmds[i].funct();
              break;
          }
          i++;
      }

      /* If the user input does not match any built-in command name, just
         ignore and read the next command. If we were to execute external
         programs, on the other hand, this is where we would search for a 
         corresponding file with a matching name in the storage device, 
         load it and transfer it the execution. Left as exercise. */

      if (!cmds[i].funct)
          kwrite ("Command not found\n");
  }
}


/* Array with built-in command names and respective function pointers. 
   Function prototypes are in kernel.h. */

struct cmd_t cmds[] =
  {
    {"help",    f_help},     /* Print a help message.       */
    {"list",    f_list},     /* Print a help message.       */
    {"exec",    f_exec},     /* Print a help message.       */
    {"quit",    f_quit},     /* Exit TyDOS.                 */
    {0, 0}
  };

struct fs_header_t *get_fs_header(){
    return (struct fs_header_t *)FS_HEADER_ADDRESS;
}

/* Build-in shell command: help. */
void f_help(){
  kwrite ("      exec    (to execute an user program example)\n");
  kwrite ("      list    (to list files - same as ls in linux)\n");
  kwrite ("      quit    (to exit hackerDOS)\n");
}

void f_quit(){
  kwrite ("You have killed a computer machine. Bye.");
  go_on = 0;
}

/* Built-in shell command: example.

   Execute an example user program which invokes a syscall.

   The example program (built from the source 'prog.c') is statically linked
   to the kernel by the linker script (tydos.ld). In order to extend the
   example, and load and external C program, edit 'f_exec' and 'prog.c' choosing
   a different name for the entry function, such that it does not conflict with
   the 'main' function of the external program.  Even better: remove 'f_exec'
   entirely, and suppress the 'example_program' section from the tydos.ld, and
   edit the Makefile not to include 'prog.o' and 'libtydos.o' from 'tydos.bin'.

  */

// block coordinate contains all the sectors that are not boot sectors
void load_disk_into_RAM(int block_coordinate, int sectors_to_read, void *target_addres) {
  int sector_coordinate = (block_coordinate - 1) % MAX_SECTORS + 1;
  int head_coordinate = ((block_coordinate - 1) / MAX_SECTORS) % MAX_HEADS;
  int cylinder_coordinate = (block_coordinate - 1) / (MAX_HEADS * MAX_SECTORS);

  //CHS Address = (Cylinder * Heads per Cylinder) + Head + (Sector - 1)

  __asm__ volatile(
      "pusha \n"
      "mov boot_drive, %%dl \n"    /* Select the boot drive (from rt0.o). */
      "mov $0x2, %%ah \n"          /* BIOS disk service: op. read sector. */
      "mov %[sectToRead], %%al \n" /* How many sectors to read          */
      "mov %[cylCoord], %%ch \n"          /* Cylinder coordinate (starts at 0).  */
      "mov %[sectCoord], %%cl \n"  /* Sector coordinate   (starts at 1).  */
      "mov %[headCoord], %%dh \n"  /* Head coordinate     (starts at 0).      */
      "mov %[targetAddr], %%bx \n" /* Where to load the file system (rt0.o).   */
      "int $0x13 \n"               /* Call BIOS disk service 0x13.        */
      "popa \n" ::
      [headCoord] "g"(head_coordinate),
      [sectCoord] "g"(sector_coordinate),
      [cylCoord] "g"(cylinder_coordinate),
      [sectToRead] "g"(sectors_to_read),
      [targetAddr] "g"(target_addres));
}

void f_list() {
    struct fs_header_t *fs_header = get_fs_header();

    // finds end of boot sectors
    int sector_coordinate = 1 + fs_header->number_of_boot_sectors;

    // finds how many sectors to read
    int sectors_to_read = fs_header->number_of_file_entries * DIR_ENTRY_LEN / SECTOR_SIZE;

    // uses _MEM_POOL address - defined in tydos.ld
    extern byte _MEM_POOL;
    void *directory_section = (void *)&_MEM_POOL;
    
    load_disk_into_RAM(sector_coordinate, sectors_to_read, directory_section);

    for (int file_pos  = 0; file_pos < fs_header->number_of_file_entries; file_pos += DIR_ENTRY_LEN) {
        char *file_name = directory_section + file_pos;
        if (file_name[0]) {
            kwrite(file_name);
            kwrite("\n");
        }
    }
}


void f_exec() {
  char user_program[BUFF_SIZE];

  kwrite("Input the name of the program you want to execute: ");
  kread(user_program);

  // achar o binario do cara
  struct fs_header_t *fs_header = get_fs_header();

  int dir_sector_coords = 1 + fs_header->number_of_boot_sectors;
  int sectors_to_read = fs_header->number_of_file_entries * DIR_ENTRY_LEN / SECTOR_SIZE + 1;

  int memoryOffset = fs_header->number_of_file_entries * DIR_ENTRY_LEN - (sectors_to_read- 1) * 512;
  
  extern byte _MEM_POOL;
  void *dir_sector_address = (void *)&_MEM_POOL;

  load_disk_into_RAM(dir_sector_coords, sectors_to_read, dir_sector_address);

  int user_program_coords = -1;
  for (int i = 0; i < fs_header->number_of_file_entries; i++) {
    char *current_file = dir_sector_address + i * DIR_ENTRY_LEN;
    if (!strcmp(current_file, user_program)) {
      user_program_coords = dir_sector_coords + sectors_to_read + fs_header->max_file_size * i - 1;
      break;
    }
  }

  if (user_program_coords == -1) {
    kwrite("Program not found.\n");
    return;
  }

  void *program = (void *)(USER_PROGRAM_START_ADDR);
  void *program_sector_start = program - memoryOffset;

  load_disk_into_RAM(user_program_coords, fs_header->max_file_size, program_sector_start);
  
  __asm__ volatile(
          "  call get_return_addr_into_ebx \n"  // coloca o return address em ebx

          "original_return_addr: \n"  // será usado para calcular o valor que deve ser adicionado à stack

          "  push %%ebx \n"  // colocar o ebx na stack

          "  jmp *%[progAddr] \n"  // jump pra main

          "get_return_addr_into_ebx: \n"
          "  mov (%%esp), %%ebx \n"  // coloca o topo da stack em ebx

          "  mov $prog_finish, %%ecx \n"           // ecx = endereço de prog_finish
          "  sub $original_return_addr, %%ecx \n"  // ecx -= endereço de original_return_addr

          "  add %%ecx, %%ebx \n"  // soma ecx em ebx, ou seja, faz com que ebx aponte para prog_finish
          "  ret \n"

          "prog_finish:"

          ::[progAddr] "r"(program));
}
