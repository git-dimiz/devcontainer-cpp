#include <stdio.h>

int main(int argc, char const *argv[]) {
    if (argc != 1) {
        printf("Args: ");
        for (size_t i = 1; i < argc; i++) {
            printf("%s ", argv[i]);
        }
        printf("\n");
    } else {
        printf("Hello World\n");
    }
    return 0;
}
