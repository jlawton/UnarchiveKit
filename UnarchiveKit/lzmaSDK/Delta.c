/* Delta.c -- Delta converter
2009-05-26 : Igor Pavlov : Public domain */

#include <string.h>

#include "Delta.h"

void Delta_Init(Byte *state)
{
  unsigned i;
  for (i = 0; i < DELTA_STATE_SIZE; i++)
    state[i] = 0;
}

void Delta_Decode(Byte *state, unsigned delta, Byte *data, SizeT size)
{
  Byte buf[DELTA_STATE_SIZE];
  unsigned j = 0;
  memcpy(buf, state, delta);
  {
    SizeT i;
    for (i = 0; i < size;)
    {
      for (j = 0; j < delta && i < size; i++, j++)
      {
        buf[j] = data[i] = (Byte)(buf[j] + data[i]);
      }
    }
  }
  if (j == delta)
    j = 0;
  memcpy(state, buf + j, delta - j);
  memcpy(state + delta - j, buf, j);
}
