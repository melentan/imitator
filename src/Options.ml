(*****************************************************************
 *
 *                     IMITATOR II
 *
 * Convert a parsing structure into an abstract program
 *
 * Laboratoire Specification et Verification (ENS Cachan & CNRS, France)
 * Author:        Ulrich Kuehne
 * Created:       2010
 * Last modified: 2012/03/14
 *
 ****************************************************************)
 
open Arg
open Global

class imitator_options =
	object
		val mutable nb_args = 0
	
	
		(* INPUT OPTIONS *)
		
		(* imitator program file *)
		val mutable file = ref ""
		(* pi0 file *)
		val mutable pi0file = ref ""
		(* GML syntax *)
		val mutable fromGML = ref false
		
	
		(* OUTPUT OPTIONS *)
		
		(* plot cartography *)
		val mutable cart = ref false
		(* plot fancy states in dot *)
		val mutable fancy = ref false
		(* Does not print logs *)
		val mutable no_log = ref false
		(* Does not print graph of reachable states *)
		val mutable no_dot = ref false
		(* prefix for output files *)
		val mutable program_prefix = ref ""
		(* Gives statistics on number of calls *)
		val mutable statistics = ref false
		(* print time stamps *)
		val mutable timed_mode = ref false
		(* print parametric logs *)
		val mutable with_parametric_log = ref false


		(* ANALYSIS OPTIONS *)

		(* limit number of iterations *)		
		val mutable post_limit = ref None
		(* limit on runtime *)
		val mutable time_limit = ref None
		(* imitator mode *)
		val mutable imitator_mode = ref Inverse_method
		(* acyclic mode: only compare inclusion or equality of a new state with former states of the same iteration (graph depth) *)
		val mutable acyclic = ref false 
		(* tree mode: never compare inclusion or equality of any new state with a former state *)
		val mutable tree = ref false 
		(* inclusion mode *)
		val mutable inclusion = ref false
		(* do not use random values *)
		val mutable no_random = ref false
		(* autodetect sync actions *)
		val mutable sync_auto_detection = ref false
		(*On-the-fly intersection*)
		val mutable dynamic = ref false
		(*Union of last states*)
		val mutable union = ref false
		(*Returns contraint K*)
		val mutable pi_compatible = ref false 
		(* Step for the cartography *)
		val mutable step = ref NumConst.one

		(* TRANSLATION *)
		(* Translate PTA into CLP program *)
		val mutable pta2clp = ref false
		(* Translate PTA into GML program *)
		val mutable pta2gml = ref false

		(* SPECIALIZED OPTIONS*)
		(* No merging of states (former jobshop option) *)
		val mutable no_merging = ref false


		
		method acyclic = !acyclic
		method acyclic_unset = (acyclic := false)
		method cart = !cart
		method dynamic = !dynamic
		method fancy = !fancy
		method file = !file
		method fromGML = !fromGML
		method imitator_mode = !imitator_mode
		method inclusion = !inclusion
		method nb_args = nb_args
		method no_dot = !no_dot
		method no_log = !no_log
		method no_merging = !no_merging
		method no_random = !no_random
		method pi_compatible = !pi_compatible
		method post_limit = !post_limit
		method program_prefix = !program_prefix
		method pta2clp = !pta2clp
		method pta2gml = !pta2gml
		method statistics = !statistics
		method step = !step
		method sync_auto_detection = !sync_auto_detection
		method time_limit = !time_limit
		method timed_mode = !timed_mode
		method tree = !tree
		method union = !union
		method with_parametric_log = !with_parametric_log

		method pi0file = !pi0file

		
		method parse =
			let usage_msg = "Usage: " ^ program_name ^ " model.imi [reference_valuation.pi0] [options]" in

			(* Get the debug mode *)
			let rec set_debug_mode_ref debug_mode =
					let mode = try debug_mode_of_string debug_mode
						with Not_found ->
						print_error ("The debug mode '" ^ debug_mode ^ "' is not valid.");
						Arg.usage speclist usage_msg;
						abort_program ();
						exit(0); in
					set_debug_mode mode

			(* Get the mode *)
			and set_mode mode =
				(* Case: 'reachability' *)
				if mode = "reachability" then 
					imitator_mode := Reachability_analysis
				(* Case: inverse method *)
				else if mode = "inversemethod" then 
					imitator_mode := Inverse_method
				(* Case: cover *)
				else if mode = "cover" then 
					imitator_mode := Cover_cartography
				(* Case: number of iterations *)
				else try (
					(* Find the 'random' string *)
					if not (String.sub mode 0 6 = "random") then raise (Failure "toto");
					(* Find the number *)
					let number = String.sub mode 6 (String.length mode - 6) in
					imitator_mode := (Random_cartography (int_of_string number))
				) with _ -> (
					print_error ("The mode '" ^ mode ^ "' is not valid.");
					Arg.usage speclist usage_msg;
					abort_program ();
					exit(0);
				)

			(* Options *)
			and speclist = [
				("-acyclic", Set acyclic, " Test if a new state was already encountered only with states of the same depth. To be set only if the system is fully acyclic (no backward branching, i.e., no cycle). Default: 'false'");
				("-cart", Set cart, " Plot cartography before terminating the program. Uses the first two parameters with ranges. Default: false."); 
				("-debug", String set_debug_mode_ref, " Print more or less information. Can be set to 'nodebug', 'standard', 'low', 'medium', 'high', 'total'. Default: 'standard'");
				("-dynamic", Set dynamic, "Perform the on-the-fly intersection. Defaut : 'false'");
				("-fancy", Set fancy, " Generate detailed state information for dot output. Default: false.");
				("-fromGML", Set fromGML, "GML syntax for input files (experimental). Defaut : 'false'");
				("-incl", Set inclusion, " Consider an inclusion of region instead of the equality when performing the Post operation (e.g., as in algorithm IMincl defined in [AS11]). Default: 'false'");
				("-IMorig", Set pi_compatible, " Algorithm IMoriginal (defined in [AS11]): return a constraint such that no pi-incompatible state can be reached. Default: 'false'");
				("-IMunion", Set union, " Algorithm IMUnion (defined in [AS11]): Returns the union of the constraint on the parameters associated to the last state of each trace. Default: 'false'");
				("-log-prefix", Set_string program_prefix, " Sets the prefix for log files. Default: [program_file].");
				("-mode", String set_mode, " Mode for " ^ program_name ^ ". Use 'reachability' for a parametric reachability analysis (no pi0 needed). Use 'inversemethod' for the inverse method. For the behavioral cartography algorithm, use 'cover' to cover all the points within V0, or 'randomXX' where XX is a number to iterate randomly algorithm (e.g., random5 or random100). Default: 'inversemethod'.");
				("-no-dot", Set no_dot, " No graphical output using 'dot'. Default: false.");
				("-no-log", Set no_log, " No generation of log files. Default: false.");
				("-no-merging", Set no_merging, " Disable the merging technique of [AFS12]. Default: 'false' (enable)");
				("-no-random", Set no_random, " No random selection of the pi0-incompatible inequality (select the first found). Default: false.");
				("-post-limit", Int (fun i -> post_limit := Some i), " Limits the depth of the Post exploration. Default: no limit.");
				("-PTA2CLP", Unit (fun _ -> pta2clp := true; imitator_mode := Translation), "Translate PTA into a CLP program (work in progress!), and exit without performing any analysis. Defaut : 'false'");
				("-PTA2GML", Unit (fun _ -> pta2gml := true; imitator_mode := Translation), "Translate PTA into a GML program, and exit without performing any analysis. Experimental. Defaut : 'false'");
				("-statistics", Set statistics, " Print info on number of calls to PPL, and other statistics. Default: 'false'");
				("-step", String (fun i -> (* SHOULD CHECK HERE THAT STEP IS EITHER A FLOAT OR AN INT *) step := (NumConst.numconst_of_string i)), " Step for the cartography. Default: 1/1.");
				("-sync-auto-detect", Set sync_auto_detection, " Detect automatically the synchronized actions in each automaton. Default: false (consider the actions declared by the user)");
				("-time-limit", Int (fun i -> time_limit := Some i), " Time limit in seconds. Warning: no guarantee that the program will stop exactly after the given amount of time. Default: no limit.");
				("-timed", Set timed_mode, " Adds a timing information to each output of the program. Default: none.");
				("-tree", Set tree, " Does not test if a new state was already encountered. To be set ONLY if the reachability graph is a tree. Default: 'false'");
				("-with-parametric-log", Set with_parametric_log, " Adds the elimination of the clock variables in the constraints in the log files. Default: false.");
				("-version", Unit (fun _ -> print_version_string (); exit 0), " Print version string and exit.");

			] in
					
			(* function for parsing arguments *)
			let anon_fun = (fun arg ->
				(* If 1st argument: main file *)
				if nb_args = 0 then(
					nb_args <- nb_args + 1;
					file := arg;
				)
				(* If 2nd argument: pi0 file *)
				else if nb_args = 1 then(
					nb_args <- nb_args + 1;
					pi0file := arg;
				)
				(* If more than one argument : warns *)
				else (
					print_warning ("The program argument '" ^ arg ^ "' will be ignored.");
				)
			) in

			Arg.parse speclist anon_fun usage_msg;

			(* Case no file (except case translation) *)
			if nb_args < 1 then(
				print_error ("Please give a source file name.");
				Arg.usage speclist usage_msg;
				abort_program (); exit(0)
			);
			
			(* Case no pi0 file *)
			if nb_args = 1 && (!imitator_mode != Reachability_analysis) && not !pta2clp && not !pta2gml  then(
				print_error ("Please give a reference valuation file name.");
				Arg.usage speclist usage_msg;
				abort_program (); exit(0)
			);
			
			(* set program prefix *)
			if !program_prefix = "" then
			  program_prefix := !file

	end
