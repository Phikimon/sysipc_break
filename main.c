#define _GNU_SOURCE
#include "assert.h"
#include "errno.h"
#include "stdio.h"
#include "stdlib.h"
#include "unistd.h"
#include "sys/types.h"
#include "sys/ipc.h"
#include "sys/shm.h"
#include "signal.h"

void attacher(void);
void creator(void);

int main(void)
{
    int fork_ret = fork();
    if (fork_ret > 0)
    {
        creator();
        kill(fork_ret, SIGINT);
    } else
    if (fork_ret == 0)
    {
        attacher();
    } else
    if (fork_ret < 0)
    {
        perror("fork");
        exit(EXIT_FAILURE);
    }
    return 0;
}

void creator(void)
{
    int shmid = -1;
    int shmctl_ret = -1;
    struct shmid_ds ds = {0};
    //
    shmid = shmget(getpid(), 65536, IPC_CREAT|0666);
    if (shmid == -1)
    {
        perror("shmget");
        exit(EXIT_FAILURE);
    }
    //
    while (ds.shm_nattch < 1)
    {
        shmctl_ret = shmctl(shmid, IPC_STAT, &ds);
        if (shmctl_ret == -1)
        {
            perror("shmctl");
            exit(EXIT_FAILURE);
        }
    }
    //
    if (ds.shm_lpid == 0)
    {
        fprintf(stderr, "Bug found! lpid = %d; nattch = %d\n", 
                                    ds.shm_lpid, ds.shm_nattch);
    } else
    {
        fprintf(stderr, "Try again\n");
    }
    //
    shmctl_ret = shmctl(shmid, 0, IPC_RMID);
    if (shmctl_ret == -1)
    {
        perror("shmctl");
        exit(EXIT_FAILURE);
    }
}

void attacher(void)
{
    int shmid = -1;
    void* shmaddr = (void*) -1;
    //
    shmid = shmget(getppid(), 65536, 0);
    if (shmid == -1)
    {
        perror("shmget");
        exit(EXIT_FAILURE);
    }
    //
    shmaddr = shmat(shmid, NULL, 0);
    if (shmaddr == (void*) -1)
    {
        perror("shmat");
        exit(EXIT_FAILURE);
    }
    sleep(1);
}
