module sbylib.graphics.action.interpolation;

alias Interpolation = float function(float);

class Interpolate {
    static Linear = function (float t) => t;
    static SmoothInOut = function (float t) => t * t * (3 - 2 * t);
}
