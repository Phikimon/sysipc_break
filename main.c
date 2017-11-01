#define _GNU_SOURCE
#include "stdio.h"
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
        shmid = shmget(getpid(), 65536, IPC_CREAT|0666);
        while (ds.shm_nattch < 1) {
            shmctl(shmid, IPC_STAT, &ds);
        }
        if (ds.shm_nattch > 1)
            printf("Bug found! lpid = %d; nattch = %d\n",
                                        ds.shm_lpid, ds.shm_nattch);
        shmctl(shmid, 0, IPC_RMID);
    } else {
        shmid = shmget(getppid(), 65536, 0);
        shmat(shmid, NULL, 0);
        sleep(1);
    }
    return 0;
}
