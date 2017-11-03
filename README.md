### Usage
For both C and Nasm implementations usage is this
```sh
user:.../x_implementation$ ./static_sysipc_break
l 1
Bug found! shm_atime = 0; lpid = 0; nattch = 1
```
Or
```sh
user:.../x_implementation$ ./static_sysipc_break
n 1
Bug found! shm_atime = xxx; lpid = xxx; nattch = 2
```
###Arguments
First letter can be 'n' or 'l' depending on the bug you'd like to find.

Second letter can be '0' or other. If it's not equal to '0' then child process sleeps for 1 sec before dying. This can increase dramatically the likeliness of bug finding.
