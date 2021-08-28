# NexNix

## What is NexNix?
NexNix is an aim to create a true modern UNIX system. But what does that entail? The UNIX philosophy is about simplicity. Looking at our selection, we can see that is not true of systems like Linux. The BSDs are better, but still quite complex. NexNix aims to be understandible by the masses. It could be used to teach how a production level OS works.
## Goals
NexNix is a microkernel. It is designed to be modular, stable, and secure, while being fast and portable. NexNix will also stay in the Unix philosophy of simplicity.
Here are the main abstract goals:<br>
Security - NexNix will be secure above all else. This involves a capbility based model, with ACLs on files. User security will be tight, and the kernel will be very stringent<br>
Performance - NexNix will be as fast as possible. This will involve using optimal algorithms throughout the kernel. Effecient algorithms will be chosen over simpler, subpar ones<br>
Portability - NexNix must be able to run on a large variety of systems. It should also take advantage of the hardware features of modern systems, though it won't depend on them<br>
Simplicity - Within the above constraints, NexNix should abide by the UNIX philosophy of simplicity as much as possible
