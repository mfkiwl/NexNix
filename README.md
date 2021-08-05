# NexNix

## What is NexNix?
NexNix is an aim to create a true modern UNIX system. But what does that entail? The UNIX philosophy is about simplicity. Looking at our selection, we can see that is not true of systems like Linux. The BSDs are better, but still quite complex. NexNix aims to be understandible by the masses. It could be used to teach how a production level OS works.
## Goals
I have constantly gone back and forth between monolithic and microkernels. In the end, however, I choose a hybrid kernel that is more micro then Windows. This basically entails having a modular kernel that first party filesystems, disk drivers, and so on run in, but untested, untrusted code is put in user space. This seems to be a good balance between the extreme micro and the extreme monolithic. 
Here are the main abstract goals:<br>
Security - NexNix will be secure above all else. This involves a capbility based model, with ACLs on files. User security will be tight, and the kernel will be very stringent<br>
Performance - NexNix will be as fast as possible. This will involve using optimal algorithms throughout the kernel. Effecient algorithms will be chosen over simpler, subpar ones<br>
Portability - NexNix must be able to run on a large variety of systems. It should also take advantage of the hardware features of modern systems, though it won't depend on them<br>
Simplicity - Within the above constraints, NexNix should abide by the UNIX philosophy of simplicity as much as possible
