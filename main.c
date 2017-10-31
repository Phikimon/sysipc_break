#define _GNU_SOURCE
#include "stdio.h"
#include <sys/syscall.h>
#include "unistd.h"
#include "sys/types.h"
#include "sys/ipc.h"
#include "sys/shm.h"

int main(void)
{
    int fork_ret = fork();
    int shmid = -1;
    struct shmid_ds ds = {0};

    if (fork_ret > 0) {
        //shmget
        shmid = (int) syscall(29, getpid(), 65536, IPC_CREAT|0666);
        while (ds.shm_nattch < 1) {
            //shmctl
            syscall(31, shmid, IPC_STAT, &ds);
        }
        if (ds.shm_lpid == 0)
            printf("Bug found! lpid = %d; nattch = %d\n",
                                        ds.shm_lpid, ds.shm_nattch);
        syscall(31, shmid, 0, IPC_RMID);
    } else {
        shmid = (int) syscall(29, getppid(), 65536, 0);
        syscall(30, shmid, NULL, 0);
        sleep(1);
    }
    return 0;
}
