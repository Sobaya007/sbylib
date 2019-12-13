module sbylib.graphics.action.run;

import sbylib.graphics.action.action : IAction, ImplAction;

public import std.datetime;
public import sbylib.event : VoidEvent;

class RunAction : IAction {

    private void delegate() f;

    mixin ImplAction;

    this(void delegate() g) {
        import sbylib.event : when, Frame, then, until;
        this.f = {
            g();

            bool executed;
            when(Frame).then({
                notifyFinish();
                executed = true;
            }).until(() => executed);
        };
    }

    this(void delegate(void delegate()) g) {
        this.f = {
            g(&notifyFinish);
        };
    }

    override void start() {
        f();
    }
}
