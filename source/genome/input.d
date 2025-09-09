module genome.input;

/// Raylib keys, but my own because I don't want make strong dependency on raylib
public enum Keys
{
    none = 0,
    apostrophe = 39,
    comma = 44,
    minus,
    period,
    slash,
    zero,
    one,
    two,
    three,
    four,
    five,
    six,
    seven,
    eight,
    nine,
    semicolon,
    equal,
    a = 65,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    i,
    j,
    k,
    l,
    m,
    n,
    o,
    p,
    q,
    r,
    s,
    t,
    u,
    v,
    w,
    x,
    y,
    z,
    // Currently i don't need more keys.
    escape = 256
}
public struct Input
{
    import raylib;
public:
static:
    /// Was key pressed this frame?
    bool isKeyDown(Keys key)
    {
        return raylib.IsKeyDown(key);
    }
}