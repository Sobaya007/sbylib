module sbylib.graphics.action.animation;

public import std.datetime;
public import sbylib.graphics.action.interpolation : Interpolation;
import sbylib.graphics.action.action : IAction, ImplAction;

class Animation(T) : IAction {
    private T delegate() getValue;
    private void delegate(T) setValue;
    private void delegate(float) updateFunction;
    private Duration _period;

    mixin ImplAction;

    this(T delegate() getter, void delegate(T) setter) {
        this.getValue = getter;
        this.setValue = setter;
    }

    this(ref T value) {
        this.getValue = () => value;
        this.setValue = (T v) { value = v; };
    }

    Animation to(T arrival) {
        import std.typecons : Nullable, nullable;

        Nullable!T departure;
        updateFunction = (float t) {
            if (departure.isNull) departure = getValue().nullable;
            setValue(T(departure.get() + (arrival - departure.get()) * t));
        };

        return this;
    }

    Animation interpolate(Interpolation i) {
        const b = updateFunction;
        updateFunction = (float t) => b(i(t));
        return this;
    }

    Animation period(Duration period) {
        this._period = period;
        return this;
    }

    override void start() {
        import std.datetime : Clock;
        import sbylib.event : when, then, until, Frame, finish;

        auto starttime = Clock.currTime;

        auto event = when(Frame).then({
            auto t = cast(float)(Clock.currTime - starttime).total!("msecs") / _period.total!("msecs");
            updateFunction(t);
        })
        .until(() => Clock.currTime > starttime + _period || killed);

        when(event.finish).then({
            this.notifyFinish();
        });
    }
}
