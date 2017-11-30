#define _GNU_SOURCE
#include "stdio.h"
#include "unistd.h"
#include "sys/types.h"
#include "sys/ipc.h"
#include "sys/shm.h"

int main(void)
{
    while (1) {
        int chld_pid = fork();
        int shmid = -1;
        struct shmid_ds ds = {0};
        if (chld_pid > 0) {
            shmid = shmget(chld_pid, 1, IPC_CREAT|0666);
            while (ds.shm_nattch < 1)
                shmctl(shmid, IPC_STAT, &ds);
            if  (ds.shm_atime == 0 || ds.shm_lpid == 0) {
                printf("Bug found! shm_atime = %d; lpid = %d; nattch = %d\n",
                                   ds.shm_atime, ds.shm_lpid, ds.shm_nattch);
                return 0;
            }
            shmctl(shmid, 0, IPC_RMID);
        } else {
            do {
                shmid = shmget(getpid(), 1, 0);
            } while (shmid < 0);
            shmat(shmid, NULL, 0);
            usleep(100000); //< To load your CPUs
            return 0;
        }
    }
}
