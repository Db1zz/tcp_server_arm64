.include "sys_calls.s"
.extern socket

.text
.global _main
.align 8

#define STDIN    0 
#define STDOUT   1
#define STDERR   2

#define PORT       14619
#define INADDR_ANY 0

#define AF_INET 2
#define SOCK_STREAM 1
#define INTERNET_PROTOCOL 0

.macro load_addr register, addr
	adrp \register, \addr@PAGE
	add \register, \register, \addr@PAGEOFF
.endm

.macro func_call func, p0, p1, p2
	mov X0, \p0
	mov X1, \p1
	mov X2, \p2
	bl \func
.endm

// int sockfd = socket(domain, type, protocol);
.macro socket domain, type, protocol
	func_call _socket, \domain, \type, \protocol
.endm

// int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
.macro bind sockfd, addr, addrlen
	func_call _bind, \sockfd, \addr, \addrlen
.endm

// int listen(int sockfd, int backlog);
.macro listen sockfd, backlog
	mov X0, \sockfd
	mov X1, \backlog
	bl _listen
.endm

// int accept(int, struct sockaddr * __restrict, socklen_t * __restrict)
.macro accept sockfd, addr, addrlen
	func_call _accept, \sockfd, \addr, \addrlen
.endm

// int close(int fd);
.macro close fd
	mov X0, \fd
	bl _close
.endm

.macro write fd, buff_addr, len_addr
	mov X0, \fd
	load_addr X1, \buff_addr
	load_addr X2, \len_addr
	ldr W2, [X2]
	bl _write
.endm

.macro exit status
	mov X16, SYS_EXIT
	mov X0, \status
	svc #0
.endm

_main:
_load_socket:
	write STDOUT, loading_socket_msg, loading_socket_msg_len
	socket AF_INET, SOCK_STREAM, #0
	cmp X0, #0
	b.lt _error
	adrp X12, sockfd@PAGE
	add X12, X12, sockfd@PAGEOFF
	str X0, [X12]
	ldr X11, [X12]

_bind_socket:
	write STDOUT, binding_socket_msg, binding_socket_msg_len
	mov X0, X11
	load_addr X1, address.sin_len
	load_addr X2, address.struct_size
	ldr X2, [X2]
	bind X0, X1, X2
	cmp X0, #0
	b.lt _error

_listen_socket:
	write STDOUT, listen_socket_msg, listen_socket_msg_len
	mov X0, X11
	listen X0, #3
	cmp X0, #0
	b.lt _error

_loop:
_accept_connections:
	write STDOUT, accept_connections_msg, accept_connections_msg_len
	mov X0, X11
	load_addr X1, address.sin_len
	load_addr X2, address.struct_size
	bl _accept
	cmp X0, #0
	b.lt _error
	load_addr X1, new_sockfd
	str X0, [X1]

_send_response:
	load_addr X0, new_sockfd
	ldr X0, [X0]
	write X0, server_response_msg, server_response_msg_len
	b _exit

_close_fds:
	stp X29, X30, [sp, #-16]!
	load_addr X0, sockfd
	ldr X0, [X0]
	bl _close
	load_addr X0, new_sockfd
	ldr X0, [X0]
	bl _close
	ldp X29, X30, [sp], #16
	ret

_error:
	write STDOUT, error_msg, error_msg_len
	bl _close_fds
	exit #-1

_exit:
	write STDOUT, ok_msg, ok_msg_len
	bl _close_fds
	exit #0

.data
.align 8
// Socket fds
sockfd:     .xword 0
new_sockfd: .xword 0

// Structs
// Socket address, internet style.
/*
	struct sockaddr_in {
		__uint8_t       sin_len;
		sa_family_t     sin_family;
		in_port_t       sin_port;
		struct  in_addr sin_addr;
		char            sin_zero[8];
	};
*/
address.sin_len:     .byte 0
address.sin_fam:     .byte AF_INET
address.sin_port:    .hword PORT
address.sin_addr:    .word INADDR_ANY
address.sin_zero:    .dword 0
address.struct_size: .word 16

// Messages
loading_socket_msg: .asciz "INFO: Loading Socket...\n"
loading_socket_msg_len: .word loading_socket_msg_len - loading_socket_msg
binding_socket_msg: .asciz "INFO: Binding Socket...\n"
binding_socket_msg_len: .word binding_socket_msg_len - binding_socket_msg
listen_socket_msg: .asciz "INFO: Listening Socket...\n"
listen_socket_msg_len: .word listen_socket_msg_len - listen_socket_msg
accept_connections_msg: .asciz "INFO: Accepting connections...\n"
accept_connections_msg_len: .word accept_connections_msg_len - accept_connections_msg
server_response_msg: .asciz "Hello from ARM64 ASM!\n"
server_response_msg_len: .word server_response_msg_len - server_response_msg
error_msg: .asciz "INFO: Error!\n"
error_msg_len: .word error_msg_len - error_msg
ok_msg: .asciz "INFO: OK!\n"
ok_msg_len: .word ok_msg_len - ok_msg