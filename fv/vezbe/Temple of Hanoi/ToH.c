#include <stdio.h>
#include <stdlib.h>

#define MAX_DISKS 64

struct Stack
{
  int data[MAX_DISKS];
  int top;
};

void initStack(struct Stack *s)
{
  s->top = -1;
}

int isEmpty(struct Stack *s)
{
  return (s->top == -1);
}

int isFull(struct Stack *s)
{
  return (s->top == MAX_DISKS - 1);
}

int push(struct Stack *s, int value)
{
  if (isFull(s))
    return 0;

  s->data[++(s->top)] = value;
  return 1;
}

int pop(struct Stack *s)
{
  if (isEmpty(s))
    return 0;

  return s->data[(s->top)--];
}

int peek(struct Stack *s)
{
  if (isEmpty(s))
    return 0;

  return s->data[s->top];
}

void towerOfHanoi(int n, char from_rod, char to_rod, char aux_rod)
{
  struct Stack from;
  struct Stack to;
  struct Stack aux;

  initStack(&from);
  initStack(&to);
  initStack(&aux);

  // Initialize the from rod with the disks in ascending order
  for (int i = n; i >= 1; i--)
    push(&from, i);

  // Loop until the to rod has all the disks
  while (to.top != n - 1)
  {
    // Move a disk from the from rod to the to rod if possible
    if (isEmpty(&to) || (!isEmpty(&from) && peek(&from) < peek(&to)))
    {
      push(&to, pop(&from));
      printf("Move disk %d from rod %c to rod %c\n", peek(&to), from_rod, to_rod);
    }
    // Move a disk from the aux rod to the to rod if possible
    else if (isEmpty(&to) || (!isEmpty(&aux) && peek(&aux) < peek(&to)))
    {
      push(&to, pop(&aux));
      printf("Move disk %d from rod %c to rod %c\n", peek(&to), aux_rod, to_rod);
    }
    // Move a disk from the from rod to the aux rod if possible
    else if (isEmpty(&aux) || (!isEmpty(&from) && peek(&from) < peek(&aux)))
    {
      push(&aux, pop(&from));
      printf("Move disk %d from rod %c to rod %c\n", peek(&aux), from_rod, aux_rod);
    }
  }
}
