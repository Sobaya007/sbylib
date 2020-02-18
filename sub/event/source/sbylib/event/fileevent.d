module sbylib.event.fileevent;

import std;
import std.digest.md : md5Of;
import sbylib.event;

private abstract class FileModifyNotification {
    abstract bool hasModified() const;
    abstract void update();

    FileModifyNotification opBinary(string op : "&")(FileModifyNotification other) {
        return new AndFileModifyNotification([this, other]);
    }

    FileModifyNotification opBinary(string op : "|")(FileModifyNotification other) {
        return new OrFileModifyNotification([this, other]);
    }
}

private class SingleFileModifyNotification : FileModifyNotification {
    private string path;
    private ubyte[16] hash;

    this(string path) {
        this.path = path;
        update();
    }

    override bool hasModified() const {
        return path.exists && md5Of(readText(path)) != hash;
    }

    override void update() {
        if (path.exists) {
            this.hash = md5Of(readText(path));
        } else {
            this.hash = typeof(hash).init;
        }
    }
}

private class AndFileModifyNotification : FileModifyNotification {
    private FileModifyNotification[] fs;

    this(FileModifyNotification[] fs) {
        this.fs = fs.dup;
    }

    override bool hasModified() const {
        return fs.all!(f => f.hasModified());
    }

    override void update() {
        foreach (f; fs) f.update();
    }
}

private class OrFileModifyNotification : FileModifyNotification {
    private FileModifyNotification[] fs;

    this(FileModifyNotification[] fs) {
        this.fs = fs.dup;
    }

    override bool hasModified() const {
        return fs.any!(f => f.hasModified());
    }

    override void update() {
        foreach (f; fs) f.update();
    }
}

FileModifyNotification hasModified(string path) {
    return new SingleFileModifyNotification(path);
}

VoidEvent when(FileModifyNotification notification) {
    import sbylib.event : when;

    return VoidEvent.create(fire =>
        when(notification.hasModified()).then({
            fire();
            notification.update();
        })
    );
}

unittest {
    import std : buildPath, tempDir;
    import std.file : fwrite = write, fremove = remove;

    auto file1 = tempDir.buildPath("test1.txt");
    auto file2 = tempDir.buildPath("test2.txt");
    auto file3 = tempDir.buildPath("test3.txt");
    scope (exit) {
        fremove(file1);
        fremove(file2);
        fremove(file3);
    }

    int[3] count;
    when(file1.hasModified).then({
        count[0]++;
    });

    when(file1.hasModified & file2.hasModified).then({
        count[1]++;
    });

    when((file1.hasModified | file2.hasModified) & file3.hasModified).then({
        count[2]++;
    });

    file1.fwrite("foo");
    FrameEventWatcher.update();
    assert(count == [1,0,0]);

    file2.fwrite("foo");
    FrameEventWatcher.update();
    assert(count == [1,1,0]);

    file3.fwrite("foo");
    FrameEventWatcher.update();
    assert(count == [1,1,1]);

    file1.fwrite("bar");
    file2.fwrite("bar");
    file3.fwrite("bar");
    FrameEventWatcher.update();
    assert(count == [2,2,2]);
}
