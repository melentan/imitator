(*****************************************************************
 *
 *                       IMITATOR
 * 
 * Laboratoire Specification et Verification (ENS Cachan & CNRS, France)
 * Universite Paris 13, Sorbonne Paris Cite, LIPN (France)
 * 
 * Author:        Etienne Andre
 * 
 * Created:       2009/09/11
 * Last modified: 2015/03/19
 *
 ****************************************************************)



(****************************************************************)
(* Modules *)
(****************************************************************)
open Automaton
open Options

(****************************************************************)
(** Environment *)
(****************************************************************)


(****************************************************************)
(** Indexes *)
(****************************************************************)

type action_index = int
type action_name = string

(****************************************************************)
(** Pi 0 *)
(****************************************************************)
(* type pi0 = NumConst.t array *)
type pi0 = (*variable_index -> NumConst.t*)PVal.pval

type v0 = HyperRectangle.hyper_rectangle


(****************************************************************)
(** Types *)
(****************************************************************)

(** Type of variable in declarations *)
type var_type =
	| Var_type_clock
	| Var_type_discrete
	| Var_type_parameter

(** Type of sync actions *)
type action_type =
	| Action_type_sync
	| Action_type_nosync



(****************************************************************)
(** Transition *)
(****************************************************************)

(** update: variable_index := linear_term *)
type clock_update = clock_index 

type clock_updates =
	(* No update at all *)
	| No_update
	(* Reset to 0 only *)
	| Resets of clock_update list
	(** TO ADD: reset to constants / discrete and parameters (to allow for support by PDBM) *)
	(* Reset to arbitrary value (including discrete, parameters and clocks) *)
	| Updates of (clock_update * LinearConstraint.pxd_linear_term) list


(** update: variable_index := linear_term *)

(*** TO OPTIMIZE (in terms of dimensions!) ***)

type discrete_update = discrete_index * LinearConstraint.pxd_linear_term

(** Guard: linear constraint *)
type guard = LinearConstraint.pxd_linear_constraint

(** Invariant: linear constraint *)
type invariant = LinearConstraint.pxd_linear_constraint

(** Transition: guard, updates, destination location *)
type transition = guard * clock_updates * discrete_update list * location_index


(****************************************************************)
(** Definition of correctness property *)
(****************************************************************)
(** predicates for bad definition *)

type duration = LinearConstraint.p_linear_term

(** Definition of the property by the end user *)
type property =
	(* DEPRECATED *)
(* 	| Exists_action of action_index *)

	| Unreachable_location of automaton_index * location_index

	(* if a2 then a1 has happened before *)
	| Action_precedence_acyclic of action_index * action_index
	(* everytime a2 then a1 has happened before *)
	| Action_precedence_cyclic of action_index * action_index
	(* everytime a2 then a1 has happened exactly once before *)
	| Action_precedence_cyclicstrict of action_index * action_index

	(* if a1 then eventually a2 *)
	| Eventual_response_acyclic of action_index * action_index
	(* everytime a1 then eventually a2 *)
	| Eventual_response_cyclic of action_index * action_index
	(* everytime a1 then eventually a2 once before next *)
	| Eventual_response_cyclicstrict of action_index * action_index

	(* a no later than d *)
	| Action_deadline of action_index * duration

	(* if a2 then a1 happened within d before *)
	| TB_Action_precedence_acyclic of action_index * action_index * duration
	(* everytime a2 then a1 happened within d before *)
	| TB_Action_precedence_cyclic of action_index * action_index * duration
	(* everytime a2 then a1 happened once within d before *)
	| TB_Action_precedence_cyclicstrict of action_index * action_index * duration
	
	(* if a1 then eventually a2 within d *)
	| TB_response_acyclic of action_index * action_index * duration
	(* everytime a1 then eventually a2 within d *)
	| TB_response_cyclic of action_index * action_index * duration
	(* everytime a1 then eventually a2 within d once before next *)
	| TB_response_cyclicstrict of action_index * action_index * duration

	(* sequence: a1, ..., an *)
	| Sequence_acyclic of action_index list
	(* sequence: always a1, ..., an *)
	| Sequence_cyclic of action_index list
	
	(* Would be better to have a "option" type *)
	| Noproperty


(* TODO: allow several definitions *)
type property_definition  = property (*list*)


(** Reduction to (non-)reachability checking *)

type reachability_property =
	(* Location never reachable *)
	| Unreachable of automaton_index * location_index
	(* Location reachable for each trace *)
	| Reachable of automaton_index * location_index
	(* Combining the two properties *)
	| Unreachable_and_reachable of automaton_index * location_index * automaton_index * location_index


type correctness_condition = reachability_property option

type projection = (parameter_index list) option

(****************************************************************)
(** Nature of the tiles *)
(****************************************************************)
(*** BADPROG : nothing to do with abstract model ! ***)
type tile_nature =
	| Good
	| Bad
	| Unknown


(****************************************************************)
(** The abstract model *)
(****************************************************************)
type abstract_model = {
	(* Cardinality *)
	nb_automata : int;
	nb_actions : int;
	nb_clocks : int;
	nb_discrete : int;
	nb_parameters : int;
	nb_variables : int;
	
	(* The list of clock indexes *)
	clocks : clock_index list;
	(* True for clocks, false otherwise *)
	is_clock : variable_index -> bool;
	(* The list of discrete indexes *)
	discrete : discrete_index list;
	(* True for discrete, false otherwise *)
	is_discrete : variable_index -> bool;
	(* The list of parameter indexes *)
	parameters : parameter_index list;
	(* The non parameters (clocks and discrete) *)
	clocks_and_discrete : variable_index list;
	(* The non clocks (parameters and discrete) *)
	parameters_and_discrete : variable_index list;
	(* The function : variable_index -> variable name *)
	variable_names : variable_index -> variable_name;
	(* The type of variables *)
	type_of_variables : variable_index -> var_type;
	
	(* The automata *)
	automata : automaton_index list;
	(* The automata names *)
	automata_names : automaton_index -> automaton_name;
	
	(* The locations for each automaton *)
	locations_per_automaton : automaton_index -> location_index list;
	(* The location names for each automaton *)
	location_names : automaton_index -> location_index -> location_name;

	(* All action indexes *)
	actions : action_index list;
	(* Action names *)
	action_names : action_index -> action_name;
	(* The type of actions *)
	action_types : action_index -> action_type;
	(* The list of actions for each automaton *)
	actions_per_automaton : automaton_index -> (action_index list);
	(* The list of automatons for each action *)
	automata_per_action : action_index -> (automaton_index list);
	(* The list of actions for each automaton for each location *)
	actions_per_location : automaton_index -> location_index -> (action_index list);

	(* The cost for each automaton and each location *)
	costs : automaton_index -> location_index -> LinearConstraint.p_linear_term option;
	
	(* The invariant for each automaton and each location *)
	invariants : automaton_index -> location_index -> invariant;
	
	(* The transitions for each automaton and each location and each action *)
	transitions : automaton_index -> location_index -> action_index -> (transition list);
	(* The list of clocks stopped for each automaton and each location *)
	stopwatches : automaton_index -> location_index -> clock_index list;
	(* Is there any stopwatch in the model? *)
	has_stopwatches : bool;

	(* Init : the initial state *)
	initial_location : global_location;
	(* Init : the initial state *)
	initial_constraint : LinearConstraint.px_linear_constraint;

	(* Property defined by the user *)
	user_property : property_definition;
	(* Property defined by the model *)
	correctness_condition : correctness_condition;
	(* List of parameters to project the result onto *)
	projection : projection;
	
	(* Set of polyhedra (only used for direct cartography without running the model) *)
	(*** BADPROG ***)
	carto : (LinearConstraint.p_linear_constraint * tile_nature) list * (NumConst.t * NumConst.t) * (NumConst.t * NumConst.t);
}



(****************************************************************)
(** Result *)
(****************************************************************)

(*** BADPROG: should NOT be here! but rather in Reachability or something like this ***)
(** Constraint returned by the inverse method *)
type returned_constraint =
	(*** TODO: merge these 2 objects (Convex_constraint and Union_of_constraints) ***)
	(** Constraint under convex form *)
	| Convex_constraint of LinearConstraint.p_linear_constraint * tile_nature
	
	(** Disjunction of constraints *)
	| Union_of_constraints of LinearConstraint.p_linear_constraint list * tile_nature

	(*** BADPROG: NNCC should NOT be here! but rather in LinearConstraint ***)
	(** Non-necessarily convex constraint: set of constraints MINUS a set of negations of constraints *)
	| NNCConstraint of (LinearConstraint.p_linear_constraint list) * (LinearConstraint.p_linear_constraint list) * tile_nature
