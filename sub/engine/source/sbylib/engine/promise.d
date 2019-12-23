module sbylib.engine.promise;

import std;
import core.thread;
import sbylib.event;

class Promise(T) {

    alias Type = T;

    private VoidEvent task;
    private Exception e;

    static if (!is(T == void)) {
        private Nullable!T result;
    }

    static if (is(T == void)) {
        this(void delegate(void delegate()) f) {
            this.task = when(Frame).then({});
            f({ this.task.kill(); });
        }
    } else {
        this(void delegate(void delegate(T)) f) {
            this.task = when(Frame).then({});
            f((T t) {
                result = t.nullable;
                // writeln("result = ", t);
                this.task.kill();
            });
        }
    }

    this(Args...)(T delegate(Args) f, Args args) {
        this.task = when(Frame).once({
            this.exec(f, args);
        });
    }

    this(Args...)(T delegate(Args) f, Promise!Args parent) {
        this.task = when(Frame).then({
            // writeln("po");
            if (parent.finished is false) return;
            static if (is(P.Type == void)) {
                this.exec(f);
            } else {
                // for avoid execution on parent's error
                if (parent.result.isNull is false) {
                    this.exec(f, parent.result.get());
                }
            }
            this.task.kill();
        });
    }

    this(Args...)(Promise!T delegate(Args) f, Promise!Args parent) {
        this.task = when(Frame).then({
            if (parent.finished is false) return;
            static if (is(P.Ret == void)) {
                this.exec(f);
            } else {
                this.exec(f, parent.result.get());
            }
        });
    }

    private void exec(Args...)(T delegate(Args) f, Args args) {
        execWithErrorHandling({
            static if (is(T == void)) {
                f(args);
            } else {
                result = f(args).nullable;
            }
        });
    }

    private void exec(Args...)(Promise!T delegate(Args) f, Args args) {
        execWithErrorHandling({
            static if (is(T == void)) {
                f(args).then({
                    this.task.kill();
                });
            } else {
                f(args).then((r) {
                    result = r.nullable;
                    this.task.kill();
                });
            }
        });
    }

    private void execWithErrorHandling(void delegate() func) {
        try {
            func();
        } catch (Exception e) {
            this.e = e;
        }
    }

    auto then(F)(F f) {
        static if (isInstanceOf!(Promise, ReturnType!F)) {
            static if (is(F == delegate)) {
                return new Promise!(ReturnType!(F).Type)(f, this);
            } else {
                return new Promise!(ReturnType!(F).Type)(f.toDelegate(), this);
            }
        } else {
            static if (is(F == delegate)) {
                return new Promise!(ReturnType!F)(f, this);
            } else {
                return new Promise!(ReturnType!F)(f.toDelegate(), this);
            }
        }
    }

    auto error(Ex)(void delegate(Ex) f) {
        when(this.e !is null).then({
            f(cast(Ex)this.e);
        });
        return this;
    }

    bool finished() 
    {
        return this.task.isAlive is false;
    }
}

auto promise(alias f)(Parameters!f args) {
    static if (is (f == delegate)) {
        return new Promise!(ReturnType!f)(f, args);
    } else {
        return new Promise!(ReturnType!f)(f.toDelegate(), args);
    }
}

auto promise(alias f)() if (is(Parameters!f[0] == delegate)) {
    static if (is (f == delegate)) {
        return new Promise!(Parameters!(Parameters!f[0])[0])(f);
    } else {
        return new Promise!(Parameters!(Parameters!f[0])[0])(f.toDelegate());
    }
}
