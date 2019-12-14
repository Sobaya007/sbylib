module sbylib.graphics.action.action;

public import sbylib.event : VoidEvent;

alias ActionFinishCallback = void delegate();
struct ActionFinishNotification { IAction action; }

interface IAction {
    void start();
    void kill();
    void addFinishCallback(ActionFinishCallback);
    final ActionFinishNotification finish() { return ActionFinishNotification(this); }
}

VoidEvent when(ActionFinishNotification notification) {
    auto event = new VoidEvent;
    notification.action.addFinishCallback({ event.fire(); });
    return event;
}

mixin template ImplAction() {

    import std.container : Array;
    import sbylib.graphics.action.action : ActionFinishCallback, ActionFinishNotification; 

    private Array!(ActionFinishCallback) callbackList;

    override void addFinishCallback(ActionFinishCallback cb) {
        this.callbackList ~= cb;
    }

    private void notifyFinish() {
        for (int i = 0; i < this.callbackList.length; i++) {
            callbackList[i]();
        }
        callbackList.clear();
    }

    private bool killed;

    void kill() {
        this.killed = true;
    }
}
