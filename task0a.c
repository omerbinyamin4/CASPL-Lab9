
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <elf.h>



int main(int argc, char **argv) {
    int fd, i;
    void *map_start;
    struct stat file_stat;
    Elf32_Ehdr *header;
    Elf32_Phdr *pheader;

    fd = open(argv[1], O_RDONLY);
    if (fd < 0){
        perror("Failed to open file");
        exit(1);
    }
    if (fstat(fd, &file_stat) == -1){
        perror("Failed to stat");
        exit(1);
    }

    map_start = mmap(NULL, file_stat.st_size, PROT_READ, MAP_SHARED, fd, 0);
    if (map_start == MAP_FAILED){
        perror("Failed to map file");
        exit(1);
    }

    header = (Elf32_Ehdr *) map_start;

    if (header->e_ident[1] != 'E' || header->e_ident[2] != 'L' || header->e_ident[3] != 'F'){
        fprintf(stderr, "Not an ELF File\n");
        munmap(map_start, file_stat.st_size);
        close(fd);
        fd = -1;
        exit(1);
    }

    pheader = (Elf32_Phdr *)(map_start + header->e_phoff);
    printf("[index]\tType\tOffset\tVirAddrt\tPhysAddr\tFileSiz\tMemSiz\tFlg\tAlign\n");

    for ( i = 0; i < header->e_phnum; i++){
        printf("[%2d]\t%3x\t%3x\t%3x\t%3x\t%3x\t%3x\t%3x\t%3x\n", i, pheader[i].p_type,  //type of segment
                                                                     pheader[i].p_offset, //
                                                                     pheader[i].p_vaddr,
                                                                     pheader[i].p_paddr,
                                                                     pheader[i].p_filesz,
                                                                     pheader[i].p_memsz,
                                                                     pheader[i].p_flags,
                                                                     pheader[i].p_align);
    }
    munmap(map_start, file_stat.st_size);
    close(fd);
    fd = -1;
    exit(1);

}