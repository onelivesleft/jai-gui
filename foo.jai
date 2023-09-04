#import "Basic";
#import "Compiler";

foo :: (call := #caller_code) -> bool, int #expand {
    do_calculate_int :: #run -> bool {
        nodes := compiler_get_nodes(call);
        assert(nodes.kind == .PROCEDURE_CALL);
        procedure_call := cast(*Code_Procedure_Call)nodes;
        return procedure_call.num_return_values_received >= 2;
    }
    i := 0;
    if do_calculate_int  i = 100;
    print("i is %\n", i);
    return true, i;
}

main :: () {
    a := false;
    b := 0;

    a = foo();
    print("% %\n", a, b);

    a, b = foo();
    print("% %\n", a, b);
}
