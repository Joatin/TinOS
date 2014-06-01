TinOS
=====

TinOS is the codename of a new Operating System project. The goal is to create a OS that only runs managed code with great performance. It is inspired from Microsofts project Singularity. However, instead of performing JIT compilation, the idea behind this attempt is to compile it at install time instead, that way all uneccessary time spent compiling the program when restarting it is avoided. 

Since all programs will be compiled on installation it gives a whole new opertunity to perform security checks during compilation instead of during runtime. And together with the new feature with relative adressing it could theoreticly be possible to run several programs in the same adressspace. The removal of context-switching could give a great performance gain as well as better battery effiency. 

A new file system called TinOS Secure File System (TOSFS for now). It is going to support per file encryption, journaling, checksums of data blocks, and a sort of software raid for important files.

The OS will also be built with the idea that it might run in a very concurrent environment. Who knows, in the near future a OS might be required to run on hundreds, or even thousands of cores. 
