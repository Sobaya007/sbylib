module sbylib.engine.event;

import sbylib.event;

struct EngineStopNotifier { }
VoidEvent[] engineStopEventList;

EngineStopNotifier engineStopping() {
    return EngineStopNotifier();
}

VoidEvent when(EngineStopNotifier) {
    auto result = new VoidEvent;
    engineStopEventList ~= result;
    return result;
}
