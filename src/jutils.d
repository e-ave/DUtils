module dutils.java;

import std.algorithm.searching : find;
import std.conv : to;
import std.exception : Exception;
import std.range : front, empty;
import std.traits : EnumMembers, fullyQualifiedName;

version(unittest) {
    import std.stdio : writeln, writefln;
}

public:

    /**
     * Finds an enum member based on it's ID.
     *
     * Enums supplied to this method must extend
     * a struct with the int 'id' in it.
     * If nothing is found an exception is thrown.
     * Returns the first member with the ID.
     *
     */
    E findEnumMember(E)(int id) if (is(E == enum)) {
        auto found = [EnumMembers!E].find!(a => a.id == id)();
        if(found.empty)
            throw new Exception(fullyQualifiedName!E ~ " contains no member with id " ~ to!string(id));
            
        return found.front;    
    }
    
    @safe unittest {
        struct S { uint id; string s; }
        enum E : S { A = S(1), B = S(2), C = S(12), D = S(12, "b") }
        assert(findEnumMember!E(12) == E.C);
    }
    
    /**
     * Wraps a primitive in an object
     */
    class Wrapped(T) {
        T _v;
        alias _v this;
        this(in T v) immutable {_v = v;};
    }
    
    unittest {
        Object i = new Wrapped!int(12);
        Object l = new Wrapped!long(12);
        int i2 = cast(Wrapped!int) i;
        long l2 = cast(Wrapped!long) l;
        assert(i != l);
        assert(i2 == l2);
    }
    
    
    /**
     * Union for converting between int bits
     * and floats
     */
    private union IEEESingle {
        int i;
        float f;
    }
        
    float intBitsToFloat(int x) {
        IEEESingle u = { i : x };
        return u.f;
    }
    
    
    int floatToRawIntBits(float x) {
        IEEESingle u = { f : x };
        return u.i;
    }
    
    int floatToIntBits(float value) {
        int result = floatToRawIntBits(value);
        // Check for NaN based on values of bit fields, maximum
        // exponent and nonzero significand.
        if (((result & 0x7F800000) == 0x7F800000) 
            && (result & 0x007FFFFF) != 0)
           result = 0x7fc00000;
        return result;
    }
    
    unittest {
        float sNaN = intBitsToFloat(0x7FBFFFFF);
        float qNaN = intBitsToFloat(0x7FFFFFFF);

        assert(floatToIntBits(sNaN) == 0x7fc00000);
        assert(floatToIntBits(qNaN) == 0x7fc00000);
        
        assert(floatToRawIntBits(sNaN) == 0x7FBFFFFF);
        assert(floatToRawIntBits(qNaN) == 0x7FFFFFFF);
        
    }
    
    /**
     * Union for converting between long bits
     * and doubles
     */
    private union IEEEDouble {
        long l;
        double d;
    }
        
    double longBitsToDouble(long x) {
        IEEEDouble u = { l : x };
        return u.d;
    }
    
    
    long doubleToRawLongBits(double x) {
        IEEEDouble u = { d : x };
        return u.l;
    }
    
    long doubleToLongBits(double value) {
        long result = doubleToRawLongBits(value);
        // Check for NaN based on values of bit fields, maximum
        // exponent and nonzero significand.
        if (((result & 0x7FF0000000000000) == 0x7FF0000000000000) 
            && (result & 0x000FFFFFFFFFFFFF) != 0)
            result = 0x7ff8000000000000;
        return result;
    }
    
    unittest {
        
        double sNaN = longBitsToDouble(0x7FF7FFFFFFFFFFFF);
        double qNaN = longBitsToDouble(0x7FFFFFFFFFFFFFFF);

        assert(doubleToLongBits(sNaN) == 0x7ff8000000000000);
        assert(doubleToLongBits(qNaN) == 0x7ff8000000000000);

        assert(doubleToRawLongBits(sNaN) == 0x7FF7FFFFFFFFFFFF);
        assert(doubleToRawLongBits(qNaN) == 0x7FFFFFFFFFFFFFFF);
    }