/*
    main.c - contains C entry point for nexboot
    SPDX-License-Identifier: ISC
*/

void nb_main()
{
    for(;;) asm("hlt");
}
