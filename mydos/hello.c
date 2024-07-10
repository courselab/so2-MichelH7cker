#include "tydos.h" 

int main(){
    char answer[BUFFER_MAX_SIZE_GETS];
    puts("How are u feeling today?\n");
    gets(answer);

    puts("you answered: ");
    puts(answer);
    puts("\n");

    return 0;
}
