%macro cdecl_entry 0
	push bp
	mov bp, sp
%endmacro

%macro cdecl_exit 0
	pop bp
	ret
%endmacro

%define cdecl_param(i) word  [ss:bp+0x04+(i*2)]

%define cdecl_var(i) word  [ss:bp-(i)]
