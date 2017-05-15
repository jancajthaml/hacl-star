/* This file was auto-generated by KreMLin! */
#ifndef __Chacha20_Vec128_H
#define __Chacha20_Vec128_H



#include "kremlib.h"
#include "testlib.h"
#include "vec128.h"

typedef uint32_t Hacl_Impl_Chacha20_Vec128_State_u32;

typedef uint32_t Hacl_Impl_Chacha20_Vec128_State_h32;

typedef uint8_t *Hacl_Impl_Chacha20_Vec128_State_uint8_p;

typedef vec *Hacl_Impl_Chacha20_Vec128_State_state;

typedef uint32_t Hacl_Impl_Chacha20_Vec128_u32;

typedef uint32_t Hacl_Impl_Chacha20_Vec128_h32;

typedef uint8_t *Hacl_Impl_Chacha20_Vec128_uint8_p;

typedef uint32_t Hacl_Impl_Chacha20_Vec128_idx;

typedef struct {
  void *x00;
  void *x01;
  uint32_t x02;
}
Hacl_Impl_Chacha20_Vec128_log_t_;

typedef void *Hacl_Impl_Chacha20_Vec128_log_t;

typedef uint8_t *Chacha20_Vec128_uint8_p;

void
Chacha20_Vec128_chacha20(
  uint8_t *output,
  uint8_t *plain,
  uint32_t len,
  uint8_t *k,
  uint8_t *n1,
  uint32_t ctr
);
#endif
