module sbylib.engine.handler;

import std;
import core.stdc.signal;
import core.stdc.stdlib;
import sbylib.engine.event;

void registerErrorHandler() {
    signal(SIGSEGV, &handler);
}

private extern (C) {
    int backtrace(void** buffer, int size);
    char** backtrace_symbols(const(void*)* buffer, int size);
    void backtrace_symbols_fd(const(void*)* buffer, int size, int fd);

    alias sigfn_t = void function(int);
    sigfn_t signal(int sig, sigfn_t func);
    void function()[] finishCallbackList;

    void handler(int) {
        enum N = 10;
        void*[N] array;
        int size;

        // get void*'s for all entries on the stack
        size = backtrace(array.ptr, N);

        writeln("\x1b[31m");
        writeln("SEGMENTATION FAULT");
        backtrace_symbols(array.ptr, size)[0..N]
            .map!(fromStringz)
            .map!(t => t.idup)
            .map!(s => s.match(ctRegex!`(.*)\((.*)\+(.*)\) \[(.*)\]`))
            .filter!(r => r.empty is false)
            .map!(r => r.front) 
            .map!(r => r[2])
            .filter!(s => s != demangle(s))
            .map!(demangle)
            .enumerate
            .each!(t => writefln("%d: %s", t.index, t.value));
        writeln("\x1b[39m");
        engineStopEventList.each!(e => e.fire());
        exit(1);
    }
}

