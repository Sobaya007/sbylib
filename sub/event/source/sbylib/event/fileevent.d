module sbylib.event.fileevent;

import std;
import std.digest.md : md5Of;
import sbylib.event;

private abstract class FileModifyNotification {
    abstract bool hasModified() const;

    FileModifyNotification opBinary(string op : "&")(in FileModifyNotification other) const {
        return new AndFileModifyNotification([this, other]);
    }

    FileModifyNotification opBinary(string op : "|")(in FileModifyNotification other) const {
        return new OrFileModifyNotification([this, other]);
    }
}

private class SingleFileModifyNotification : FileModifyNotification {
    private string path;
    private immutable ubyte[16] hash;
    private SysTime last;

    this(string path) {
        this.path = path;
        this.hash = md5Of(readText(path));
        this.last = path.timeLastModified;
    }

    override bool hasModified() const {
        return path.timeLastModified > last && md5Of(readText(path)) != hash;
    }
}

private class AndFileModifyNotification : FileModifyNotification {
    private const FileModifyNotification[] fs;

    this(const FileModifyNotification[] fs) {
        this.fs = fs;
    }

    override bool hasModified() const {
        return fs.all!(f => f.hasModified());
    }
}

private class OrFileModifyNotification : FileModifyNotification {
    private const FileModifyNotification[] fs;

    this(const FileModifyNotification[] fs) {
        this.fs = fs;
    }

    override bool hasModified() const {
        return fs.any!(f => f.hasModified());
    }
}

FileModifyNotification hasModified(string path) {
    return new SingleFileModifyNotification(path);
}

VoidEvent when(FileModifyNotification notification) {
    import sbylib.event : when, until;

    auto event = new VoidEvent;
    when(notification.hasModified()).then({
        event.fireOnce();
    }).until(() => !event.isAlive);
    return event;
}
