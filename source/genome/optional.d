module genome.optional;

/// Optional type that can hold either a value or an error.
public struct Optional(TValue, TError)
{
    public @property bool hasValue() const
    {
        return hasValue_;
    }

    public void opAssign(T)(T value) if(T is TValue)
    {
        value = value;
        hasValue_ = true;
    }

    public void opAssign(T)(T error) if(T is TError)
    {
        error = error;
        hasValue_ = false;
    }

private:
    union
    {
        TValue value;
        TError error;
    }

    bool hasValue_;
}