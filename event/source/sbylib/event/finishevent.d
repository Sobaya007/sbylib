module sbylib.event.finishevent;

import sbylib.event;

private struct FinishNotification { IEvent event; }

auto finish(IEvent event) {
    return FinishNotification(event);
}

VoidEvent when(FinishNotification finish) {
    auto event = new VoidEvent;
    event._context = null;
    finish.event.addFinishCallback({
        event.fire();
    });
    return event;
}

private struct AllFinishNotification { IEvent[] eventList; }

auto allFinish(IEvent[] eventList) {
    return AllFinishNotification(eventList);
}

VoidEvent when(AllFinishNotification finish) {
    auto event = new VoidEvent;
    event._context = null;
    auto cnt = finish.eventList.length;
    foreach (e; finish.eventList) {
        e.addFinishCallback({
            if (--cnt == 0) event.fire();
        });
    }
    return event;
}
