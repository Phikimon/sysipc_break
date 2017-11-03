#define _GNU_SOURCE
#include "stdio.h"
#include "unistd.h"
#include "sys/types.h"
#include "sys/ipc.h"
#include "sys/shm.h"

int main(void)
{
    int bug_to_find = getchar();
    int shall_child_sleep = getchar();
    while (1) {
        int fork_ret = fork();
        int shmid = -1;
        struct shmid_ds ds = {0};
        if (fork_ret > 0) {
            shmid = shmget(fork_ret, 65536, IPC_CREAT|0666);
            while (ds.shm_nattch < 1) {
                shmctl(shmid, IPC_STAT, &ds);
            }
            if ( ((ds.shm_atime == 0 || ds.shm_lpid == 0) && (bug_to_find == 'l')) ||
                 (        (ds.shm_nattch > 1)             && (bug_to_find == 'n'))  ) {
                printf("Bug found! shm_atime = %d; lpid = %d; nattch = %d\n",
                                   ds.shm_atime, ds.shm_lpid, ds.shm_nattch);
                return 0;
            }
            shmctl(shmid, 0, IPC_RMID);
        } else {
            do {
                shmid = shmget(getpid(), 65536, 0);
            } while (shmid < 0);
            shmat(shmid, NULL, 0);
            if (shall_child_sleep)
                sleep(1);
            return 0;
        }
    }
}
