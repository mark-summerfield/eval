# Copyright © 2025 Mark Summerfield. All rights reserved.

proc incr_str s {
    set s [string toupper $s]
    if {[string length $s] == 1} {
        scan $s %c u
        if {$u >= 65 && $u < 90} {
            incr u
            return [format %c $u]
        } else {
            return AA
        }
    } else {
        scan [string index $s 0] %c x
        scan [string index $s 1] %c y
        if {$y >= 65 && $y < 90} {
            incr y
        } else {
            incr x
            set y 65
        }
        return [format %c%c $x $y]
    }
}
