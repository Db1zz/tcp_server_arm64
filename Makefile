NAME = Aarch64

CC = as
LINKER = clang
FLAGS = -x assembler-with-cpp

SRCS =	main.s \
		sys_calls.s

OBJS = $(SRCS:.s=.o)

all: $(NAME)

$(NAME): $(OBJS)
	$(LINKER) -o $(NAME) $(OBJS) -lc

%.o: %.s
	$(CC) $(FLAGS) -o $@ $<

clean:
	rm -f $(OBJS)

fclean: clean
	rm -f $(NAME)

re: fclean all

.PHONY: all clean fclean re