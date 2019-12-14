module sbylib.event.fileevent;

import std;
import sbylib.event;

private struct FileModifyNotification { string path; }

auto hasModified(string path) {
    return FileModifyNotification(
        path.absolutePath.buildNormalizedPath);
}

VoidEvent when(FileModifyNotification notification) {
    import sbylib.event : when, until;

    const content = read(notification.path);
    const date = notification.path.timeLastModified;
    auto event = new VoidEvent;
    when(Frame).then({
        if (notification.path.timeLastModified > date) {
            if (read(notification.path) != content) {
                event.fireOnce();
            }
        }
    }).until(() => !event.isAlive);
    return event;
}
