(** * Writer *)

(** Output effect. *)

(* begin hide *)
Set Implicit Arguments.
Set Contextual Implicit.

From Coq Require Import
     List.
Import ListNotations.

From ExtLib Require Import
     Structures.Functor
     Structures.Monad
     Structures.Monoid.

From ITree Require Import
     Basics.Basics
     Basics.CategoryOps
     Core.ITree
     Indexed.Sum
     Indexed.OpenSum
     Interp.Interp
     Interp.Handler
     Effects.State.

Import Basics.Basics.Monads.
(* end hide *)

(** Effect to output values of type [W]. *)
Variant writerE (W : Type) : Type -> Type :=
| Tell : W -> writerE W unit.

(** Output action. *)
Definition tell {W E} `{writerE W -< E} : W -> itree E unit :=
  fun w => lift (Tell w).

(** One interpretation is to accumulate outputs in a list. *)

(** Note that this handler appends new outputs to the front of the list. *)
Definition handle_writer_list {W E}
  : writerE W ~> stateT (list W) (itree E)
  := fun _ e s =>
       match e with
       | Tell w => Ret (w :: s, tt)
       end.

Definition run_writer_list_state {W E}
  : itree (writerE W +' E) ~> stateT (list W) (itree E)
  := fun _ t => interp_state (case_ handle_writer_list pure_state) _ t.

(** Returns the outputs in order: the first output at the head, the last
    output and the end of the list. *)
Definition run_writer_list {W E}
  : itree (writerE W +' E) ~> writerT (list W) (itree E)
  := fun _ t =>
       ITree.map (fun wsx => (rev' (fst wsx), snd wsx))
                 (run_writer_list_state t []).

(** When [W] is a monoid, we can also use that to append the outputs together. *)

Definition handle_writer {W E} (Monoid_W : Monoid W)
  : writerE W ~> stateT W (itree E)
  := fun _ e s =>
       match e with
       | Tell w => Ret (monoid_plus Monoid_W s w, tt) 
       end.

Definition run_writer {W E} (Monoid_W : Monoid W)
  : itree (writerE W +' E) ~> writerT W (itree E)
  := fun _ t =>
       interp_state (case_ (handle_writer Monoid_W) pure_state) _ t
                    (monoid_unit Monoid_W).