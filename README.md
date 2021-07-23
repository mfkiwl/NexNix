# NexNix

## What is NexNix?
NexNix is an aim to create a true modern UNIX system. But what does that entail? The UNIX philosophy is about simplicity. Looking at our selection, we can see that is not true of systems like Linux. The BSDs are better, but still quite complex. NexNix aims to be understandible by the masses. It could be used to teach how a production level OS works.
## Goals
I have constantly gone back and forth between monolithic and microkernels. In the end, however, I choose a microkernel. The reasons are as follows
Security - microkernels are a lot easier to secure and protect from malicious drivers
<br>
Stability - a crashed server can be recovered in some situations. This promotes security in the overall system.
<br>
Modularity - all system components are very modular, meaning that we don't have a big mess of code
<br>
Asynchronous nature - microkernel are very asynchronous, meaning that NexNix should scale very well
<br>
The other big things I am going to pay attention to are:
Speed - nobody wants a slow system. Microkernel do have performance concerns, so, the system is planned out in a way to allow for high speed
Simplicity - everything should be as simple as possible, but not simpler, to quote Einstein. A simple system is easier to mantain and contribute to, as it is easy to pick up and learn.
Those are the goals of NexNix. It is still in early development, but much is on the way!<br>
