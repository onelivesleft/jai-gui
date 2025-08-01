#import "Basic";

main :: () {
    foo: u64;
    #asm {
        a: gpr === a;
        xor a, a;
        rbp: gpr === bp;
        mov foo, rbp;
    }
    bar := foo;
    print("%\n", bar);
}
