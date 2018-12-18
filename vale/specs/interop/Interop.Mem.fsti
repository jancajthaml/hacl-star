module Interop.Mem
open Interop.Base
module List = FStar.List.Tot.Base
module HS = FStar.Monotonic.HyperStack
module HH = FStar.Monotonic.HyperHeap
module B = LowStar.Buffer
module M = LowStar.Modifies
module MS = X64.Machine_s
module BS = X64.Bytes_Semantics_s

let op_String_Access = Map.sel
let op_String_Assignment = Map.upd

let sub l i = l - i

[@__reduce__]
let disjoint_or_eq_b8 (ptr1 ptr2:b8) = M.loc_disjoint (M.loc_buffer ptr1) (M.loc_buffer ptr2) \/ ptr1 == ptr2

[@__reduce__]
let disjoint_or_eq_b8_l (ptrs:list b8)
 : prop
 = BigOps.pairwise_and' disjoint_or_eq_b8 ptrs

let list_disjoint_or_eq (ptrs:list b8) =
  forall (p1 p2:b8). List.memP p1 ptrs /\ List.memP p2 ptrs ==> disjoint_or_eq_b8 p1 p2

unfold
let list_live (#a:Type0) mem (ptrs:list (B.buffer a)) =
  forall p . List.memP p ptrs ==> B.live mem p

let correct_down_p (mem:HS.mem) (addrs:addr_map) (heap:BS.heap) (p:b8) =
  let length = B.length p in
  let contents = B.as_seq mem p in
  let addr = addrs p in
  (forall i.  0 <= i /\ i < length ==> heap.[addr + i] == UInt8.v (FStar.Seq.index contents i))

val addrs_set (ptrs:list b8) (addrs:addr_map)
  : GTot (s:Set.set int{
                 forall x.{:pattern (Set.mem x s)}
                   not (Set.mem x s) <==> 
                   (forall (b:b8{List.memP b ptrs}).{:pattern (addrs b)}
                     x < addrs b \/ x >= addrs b + B.length b)})
    
val addrs_set_lemma (ptrs1:list b8) (ptrs2:list b8) (addrs:addr_map)
  : Lemma
    (requires forall b. List.memP b ptrs1 <==> List.memP b ptrs2)
    (ensures addrs_set ptrs1 addrs == addrs_set ptrs2 addrs)

val addrs_set_concat (ptrs:list b8) (a:b8) (addrs:addr_map)
  : Lemma
    (addrs_set (a::ptrs) addrs == Set.union (addrs_set ptrs addrs) (addrs_set [a] addrs))
  
val addrs_set_mem (ptrs:list b8) (a:b8) (addrs:addr_map) (i:int)
  : Lemma
  (requires List.memP a ptrs /\ i >= addrs a /\ i < addrs a + B.length a)
  (ensures Set.mem i (addrs_set ptrs addrs))
  
let correct_down mem (addrs:addr_map) (ptrs: list b8) heap =
  Set.equal (addrs_set ptrs addrs) (Map.domain heap) /\ 
  (forall p. List.memP p ptrs ==> correct_down_p mem addrs heap p)

(* Takes a Low* Hyperstack and a list of buffers and create a vale memory + keep track of the vale addresses *)
val down_mem (mem:HS.mem) (addrs: addr_map) (ptrs:list b8{list_disjoint_or_eq ptrs})
  : GTot (heap :BS.heap {correct_down mem addrs ptrs heap})

val same_unspecified_down: 
  (mem1: HS.mem) -> 
  (mem2: HS.mem) -> 
  (addrs:addr_map) ->
  (ptrs:list b8{list_disjoint_or_eq ptrs}) ->
  Lemma (
    let heap1 = down_mem mem1 addrs ptrs in
    let heap2 = down_mem mem2 addrs ptrs in
    forall i. (forall (b:b8{List.memP b ptrs}). 
      let base = addrs b in
      i < base \/ i >= base + B.length b) ==>
      heap1.[i] == heap2.[i])

let get_seq_heap (heap:BS.heap) (addrs:addr_map) (b:b8) : GTot (Seq.lseq UInt8.t (B.length b)) =
  let length = B.length b in
  let contents (i:nat{i < length}) = UInt8.uint_to_t heap.[addrs b + i] in
  Seq.init length contents

val up_mem: 
  (heap:BS.heap) -> 
  (addrs:addr_map) -> 
  (ptrs: list b8{list_disjoint_or_eq ptrs}) -> 
  (mem:HS.mem{list_live mem ptrs /\ Set.equal (addrs_set ptrs addrs) (Map.domain heap)}) -> 
  GTot (new_mem:HS.mem{correct_down new_mem addrs ptrs heap /\ list_live new_mem ptrs})

val down_up_identity: 
  (mem:HS.mem) -> 
  (addrs:addr_map) -> 
  (ptrs:list b8{list_disjoint_or_eq ptrs /\ list_live mem ptrs }) -> 
  Lemma (
    let heap = down_mem mem addrs ptrs in 
    let new_mem = up_mem heap addrs ptrs mem in
    mem == new_mem)

val up_down_identity:
  (mem:HS.mem) ->
  (addrs:addr_map) ->
  (ptrs:list b8{list_disjoint_or_eq ptrs /\ list_live mem ptrs}) ->
  (heap:BS.heap{Set.equal (addrs_set ptrs addrs) (Map.domain heap)}) -> 
  Lemma
    (requires (forall x. not (Map.contains heap x) ==> Map.sel heap x == Map.sel (down_mem mem addrs ptrs) x))
    (ensures (down_mem (up_mem heap addrs ptrs mem) addrs ptrs == heap))

val update_buffer_up_mem:
  (ptrs:list b8{list_disjoint_or_eq ptrs}) ->
  (addrs:addr_map) ->
  (mem:HS.mem{list_live mem ptrs}) ->
  (b:b8{List.memP b ptrs}) ->
  (heap1:BS.heap{correct_down mem addrs ptrs heap1}) ->
  (heap2:BS.heap{Set.equal (Map.domain heap1) (Map.domain heap2)}) -> Lemma
  (requires (forall x. x < addrs b \/ x >= addrs b + B.length b ==> heap1.[x] == heap2.[x]))
  (ensures up_mem heap2 addrs ptrs mem == 
    B.g_upd_seq b (get_seq_heap heap2 addrs b) mem)
