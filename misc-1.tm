# Copyright © 2025 Mark Summerfield. All rights reserved.

proc make_text_widget {parent framename} {
    const COLOR_FOR_TAG [dict create \
        white "#FFFFFF" \
        black "#000000" \
        grey "#555555" \
        navy "#000075" \
        blue "#0000FF" \
        lavender "#6767E0" \
        cyan "#007272" \
        teal "#469990" \
        olive "#676700" \
        green "#009C00" \
        lime "#608000" \
        maroon "#800000" \
        brown "#9A6324" \
        gold "#9A8100" \
        orange "#CD8400" \
        red "#FF0000" \
        pink "#FF5B77" \
        purple "#911EB4" \
        magenta "#F032E6" \
        ]
    set frm [ttk::frame $parent$framename]
    set name txt
    set txt [text $frm.$name -wrap word]
    $txt configure -font Sans
    $txt tag configure indent -lmargin2 [font measure Sans "• "]
    $txt tag configure bold -font Bold
    $txt tag configure italic -font Italic
    $txt tag configure bolditalic -font BoldItalic
    $txt tag configure ul -underline true
    $txt tag configure highlight -background yellow
    dict for {key value} $COLOR_FOR_TAG {
        $txt tag configure $key -foreground $value
    }
    $txt tag configure center -justify center
    $txt tag configure right -justify right
    ui::scrollize $frm $name vertical
    return $txt
}

proc incr_str s {
    set s [string toupper $s]
    if {[string length $s] == 1} {
        scan $s %c x
        if {$x >= 65 && $x < 90} {
            incr x
            return [format %c $x]
        } else {
            return AA
        }
    } elseif {[string length $s] == 2} {
        scan [string index $s 0] %c x
        scan [string index $s 1] %c y
        if {$y >= 65 && $y < 90} {
            incr y
        } elseif {$x >= 65 && $x < 90} {
            incr x
            set y 65
        } else {
            return AAA
        }
        return [format %c%c $x $y]
    } elseif {[string length $s] == 3} {
        scan [string index $s 0] %c x
        scan [string index $s 1] %c y
        scan [string index $s 2] %c z
        if {$z >= 65 && $z < 90} {
            incr z
        } elseif {$y >= 65 && $y < 90} {
            incr y
            set z 65
        } elseif {$x >= 65 && $x < 90} {
            incr x
            set y 65
            set z 65
        } else {
            error "incr_str is limited to A → ZZZ"
        }
        return [format %c%c%c $x $y $z]
    }
    error "incr_str is limited to A → ZZZ"
}
