# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::define App method on_eval {} {
    set eval_txt [string trim [$EvalCombo get]]
    if {$eval_txt eq ""} { return }
    if {$eval_txt eq "cls" | $eval_txt eq "clear"} {
        $AnsText delete 1.0 end
    } elseif {[regexp {\d{2,4}-\d\d?-\d\d?|\mtoday\M} $eval_txt]} {
        my do_date $eval_txt
    } elseif {[regexp -expanded {(\m|\d)(meter|km|kilo|kg|second|
            rad(?:ian)?|deg(?:gree)?|foot|ft|hectare|in(?:ch)?|
            mi(?:le)?pound|lb|yd|yards?|litres?|stones?|mm|pt|
            points?)\M} $eval_txt]} {
        my do_conversion $eval_txt
    } elseif {[regexp {[]^$\{:?\\|]} $eval_txt]} {
        my do_regexp $eval_txt
    } elseif {[string first = $eval_txt] > -1} {
        my do_assignment $eval_txt
    } elseif {[regexp {^[A-Za-z]+$} $eval_txt]} {
        my do_spellcheck $eval_txt
    } else {
        my do_expression $eval_txt
    }
    $AnsText mark set insert end
    $AnsText see end
}

oo::define App method do_regexp pattern {
    set say "$AnsText insert end"
    set re_text [string trim [$RegexTextCombo get]]
    if {$re_text eq ""} {
        {*}$say "Enter text for regexp to match…\n\n" red
        focus $RegexTextCombo
        $AnsText see end
        return
    } else {
        my update_combo $RegexTextCombo $re_text
        try {
            {*}$say "re:  " {green indent}
            {*}$say $pattern\n {blue indent}
            {*}$say "txt: " {green indent}
            {*}$say “$re_text”\n {blue indent}
            set matches [regexp -inline -- $pattern $re_text]
            if {[llength $matches]} {
                foreach match $matches i [lseq [llength $matches]] {
                    {*}$say "#$i: " {green indent}
                    {*}$say “$match”\n {blue indent}
                }
            } else {
                {*}$say "no match\n" magenta
            }
            my update_combo $EvalCombo $re_text
        } on error err {
            {*}$say $err\n red
        }
    }
}

oo::define App method do_conversion txt {
    set txt [regsub -nocase {\mto\M} $txt ""]
    set say "$AnsText insert end"
    try {
        {*}$say $txt {blue indent}
        {*}$say " → " {green indent}
        {*}$say [units::convert {*}$txt]\n {blue indent}
        my update_combo $EvalCombo $txt
    } on error err {
        {*}$say $err\n red
    }
}

oo::define App method do_date txt {
    set say "$AnsText insert end"
    set txt [regsub -all today $txt [clock format [clock scan now] \
        -format %Y-%m-%d]]
    if {[regexp -expanded {
            ((\d{2,4})-\d\d?-\d\d?) # from
            \s*([-+])\s* # op
            (
                (\d+\s+(:?days?|months?))| # add or subtract
                (\d{2,4})-\d\d?-\d\d? # or to
            )} $txt _ start year1 op by_or_end year2]} {
        try {
            set fmt [expr {$year1 < 100 ? "%y-%m-%d" : "%Y-%m-%d"}]
            set from [clock scan $start -format $fmt]
            if {[string first {-} $by_or_end] != -1} {
                set fmt [expr {$year2 < 100 ? "%y-%m-%d" : "%Y-%m-%d"}]
                set to [clock scan $by_or_end -format $fmt]
                set days [expr {abs($from - $to) / 86400}]
                {*}$say $start {blue indent}
                {*}$say " - " {green indent}
                {*}$say $by_or_end {blue indent}
                {*}$say " → " {green indent}
                {*}$say $days {blue indent}
                {*}$say " days\n" {green indent}
            } else {
                set value [clock add $from {*}"$op$by_or_end"]
                set to [clock format $value -format %Y-%m-%d]
                {*}$say "$start $op $by_or_end" {blue indent}
                {*}$say " → " {green indent}
                {*}$say $to\n {blue indent}
            }
            my update_combo $EvalCombo $txt
        } on error err {
            {*}$say $err\n red
        }
    } else {
        {*}$say "invalid date expression\n" red
    }
}

oo::define App method do_assignment txt {
    set i [string first = $txt]
    set name [string trim [string range $txt 0 $i-1]]
    set expression [string trim [string range $txt $i+1 end]]
    if {$expression eq ""} {
        dict unset Vars $name
        my refresh_vars
    } else {
        my evaluate $name $expression
    }
}

oo::define App method do_spellcheck txt {
    set say "$AnsText insert end"
    set cmd [list aspell -a]
    set reply [exec {*}$cmd << $txt 1>]
    if {[string index $reply end-1] eq "*"} {
        {*}$say "$txt ✔\n" {green indent}
    } else {
        set suggestions [list]
        set i [string first : $reply]
        if {$i > -1} {
            set reply [string trim [string range $reply \
                [expr {$i + 1}] end]]
            foreach suggestion [split $reply ,] {
                lappend suggestions [string trim $suggestion]
            }
        }
        {*}$say "$txt ✘\n" {red indent}
        {*}$say "suggestions:\n" {green indent}
        {*}$say "   [join $suggestions " "]\n" {blue indent}
    }
}

oo::define App method do_expression txt {
    my evaluate [my next_name] [string trim $txt]
}

oo::define App method evaluate {name expression} {
    set say "$AnsText insert end"
    set expression [regsub -all -command {\m[[:alpha:]]\w*\M} \
        $expression [lambda {vars match} \
            { dict getdef $vars $match $match } $Vars]]
    try {
        set value [expr $expression]
        dict set Vars $name $value
        {*}$say $name {blue indent}
        {*}$say " = " {green indent}
        set fmt [expr {[string is integer $value] ? "%Ld" : "%Lg"}]
        {*}$say [format $fmt\n $value] {blue indent}
        my update_vars_list $name
        my refresh_vars
        my update_combo $EvalCombo $expression
    } on error err {
        {*}$say $err\n red
    }
}

oo::define App method update_vars_list name {
    if {[set i [lsearch -exact $VarsList $name]] > -1} {
        set VarsList [lremove $VarsList $i]
    }
    lappend VarsList $name
    if {[llength $VarsList] > 50} {
        set VarsList [lrange $VarsList end-50 end]
    }
}
