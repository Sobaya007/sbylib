module sbylib.graphics.action.sequence;

public import std.datetime;

import sbylib.graphics.action.action : IAction, ImplAction;
import sbylib.graphics.action.animation : Animation;
import sbylib.graphics.action.run : RunAction;
import sbylib.graphics.action.wait : WaitAction;
import sbylib.event : VoidEvent;
import std.container : Array;

class ActionSequence : IAction {

    mixin ImplAction;

    private ActionNode rootAction;
    private IAction[] actionList;

    static opCall() {
        return new typeof(this);
    }

    override void start() {
        rootAction.action.start();
    }

    auto animate(string mem,T)(T value) {
        import std.traits : ReturnType;

        alias Type = ReturnType!(mixin("value."~mem));
        auto result = new Animation!Type(
            () => mixin("value."~mem),
            (Type v) { mixin("value."~mem) = v; }
        );
        add(result);
        return result;
    }

    Animation!T animate(T)(ref T value) {
        auto result = new Animation!T(value);
        add(result);
        return result;
    }

    IAction action(IAction action) {
        add(action);
        return action;
    }

    WaitAction wait(Duration dur) {
        auto result = new WaitAction(dur);
        add(result);
        return result;
    }

    RunAction run(void delegate() f) {
        auto result = new RunAction(f);
        add(result);
        return result;
    }

    RunAction run(void delegate(void delegate()) f) {
        auto result = new RunAction(f);
        add(result);
        return result;
    }

    private void add(IAction action) {
        if (rootAction is null) {
            rootAction = new ActionNode(action);
        } else {
            rootAction.add(new ActionNode(action));
        }
    }

    private void onFinish() {
        for (int j = 0; j < callbackList.length; j++) {
            callbackList[j]();
        }
        callbackList.clear();
    }

    private class ActionNode {
        IAction action;
        ActionNode next;

        this(IAction action) { 
            import sbylib.graphics.action.action : when;
            import sbylib.event.event : then;

            this.action = action; 
            when(action.finish).then({
                if (next is null) {
                    onFinish();
                } else {
                    next.action.start();
                }
                rootAction = next;
            });
        }

        void add(ActionNode node) {
            if (next is null) {
                next = node;
            } else {
                next.add(node);
            }
        }
    }
}
