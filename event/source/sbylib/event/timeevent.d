module sbylib.event.timeevent;

import std;
import sbylib.event;

struct TimeNotification {
    SysTime end;
}

auto later(Duration dur) {
  return TimeNotification(Clock.currTime + dur);
}

VoidEvent when(TimeNotification notification) {
    import sbylib.event : when, until;

    auto result = new VoidEvent;
    when(Frame).then({
        if (Clock.currTime > notification.end) {
            result.fireOnce();
        }
    }).until(() => result.isAlive is false);
    return result;
}
