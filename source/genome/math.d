module genome.math;
import std.traits : isNumeric;

pragma(inline, true)
T toRange(T)(T value, T oldMin, T oldMax, T newMin, T newMax) if(isNumeric!T)
{
    return  cast(T)((((value - oldMin) * newMax - newMin) / (oldMax - oldMin)) + newMin);
}