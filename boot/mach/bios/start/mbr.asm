; mbr.asm - contains master boot record startup code
; Copyright 2021 Jedidiah Thompson
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

bits 16
cpu 8086

%define MBR_BIOSSIG 0xAA55
%define MBR_PADMAX 510
%define MBR_BASE 0x600

start:
    cli
    hlt

; Pad it out to 510 bytes
times MBR_PADMAX - ($ - $$) db 0
dw MBR_BIOSSIG
