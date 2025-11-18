# Copyright © 2025 Mark Summerfield. All rights reserved.

proc make_text_widget {parent framename} {
    const COLOR_FOR_TAG [dict create \
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
    set Text [text $frm.$name -wrap word]
    $Text configure -font Sans
    $Text tag configure indent -lmargin2 [font measure Sans "nn"]
    $Text tag configure bold -font Bold
    $Text tag configure italic -font Italic
    $Text tag configure bolditalic -font BoldItalic
    $Text tag configure ul -underline true
    $Text tag configure highlight -background yellow
    dict for {key value} $COLOR_FOR_TAG {
        $Text tag configure $key -foreground $value
    }
    $Text tag configure center -justify center
    $Text tag configure right -justify right
    ui::scrollize $frm $name vertical
    return $Text
}

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
