# Copyright © 2025 Mark Summerfield. All rights reserved.

oo::define App method on_eval {} {
    set eval_txt [string trim [$EvalCombo get]]
    if {$eval_txt eq ""} { return }
    if {$eval_txt eq "?" | $eval_txt eq "help"} {
        my do_help
    } elseif {$eval_txt eq "cls" | $eval_txt eq "clear"} {
        $AnsText delete 1.0 end
    } elseif {[regexp {\d{2,4}-\d\d?-\d\d?} $eval_txt]} {
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
    } else {
        my do_expression $eval_txt
    }
    $AnsText mark set insert end
    $AnsText see end
}

oo::define App method do_help {} {
    set say "$AnsText insert end"
    {*}$say Help\n {bold magenta center}
    {*}$say "Enter one of the following:\n" indent
    {*}$say "Help: " {navy italic indent}
    {*}$say ? {blue indent}
    {*}$say " or " indent
    {*}$say help {blue indent}
    {*}$say " to show this help text.\n" indent
    {*}$say Expression {navy italic indent}
    {*}$say ", e.g., " indent
    {*}$say "rand() * 5" {blue indent}
    {*}$say " or " indent
    {*}$say "19 / 7" {blue indent}
    {*}$say ".\n" indent
    {*}$say "Assignment expression" {navy italic indent}
    {*}$say ", e.g., " indent
    {*}$say "a = 14 ** 2" {blue indent}
    {*}$say ".\n" indent
    {*}$say "Tcl regexp" {navy italic indent}
    {*}$say " (and text for the regexp to match), e.g., " indent
    {*}$say "(\\w+)\\s*=\\s*(.*)" {blue indent}
    {*}$say ", and, e.g., " indent
    {*}$say "width = 17" {blue indent}
    {*}$say ".\n" indent
    {*}$say Conversion {navy italic indent}
    {*}$say ", e.g., " indent
    {*}$say "69kg to stone" {blue indent}
    {*}$say " (the 'to' is optional).\n" indent
    {*}$say "Date expression" {navy italic indent}
    {*}$say ", e.g., " indent
    {*}$say "25-11-14 + 120 days" {blue indent}
    {*}$say " or " indent
    {*}$say "25-11-14 - 25-7-19" {blue indent}
    {*}$say "." indent
    {*}$say "\nDelete a variable: " {navy italic indent}
    {*}$say "enter " indent
    {*}$say "varname" {indent blue italic}
    {*}$say "=" {indent blue}
    {*}$say "\nClear: " {navy italic indent}
    {*}$say "enter " indent
    {*}$say "cls" {indent blue italic}
    {*}$say " or " indent
    {*}$say "clear" {indent blue italic}
    {*}$say ".\nPress " indent
    {*}$say Return {blue bold indent}
    {*}$say " to calculate.\n\n" indent
    {*}$say "Some supported functions: " indent
    {*}$say hypot( {purple indent}
    {*}$say x {italic purple indent}
    {*}$say ", " {purple indent}
    {*}$say y {italic purple indent}
    {*}$say ")" {purple indent}
    {*}$say ", " indent
    {*}$say log( {purple indent}
    {*}$say x {italic purple indent}
    {*}$say ")" {purple indent}
    {*}$say ", " indent
    {*}$say log10( {purple indent}
    {*}$say x {italic purple indent}
    {*}$say ")" {purple indent}
    {*}$say ", " indent
    {*}$say rand() {purple indent}
    {*}$say ", " indent
    {*}$say sqrt( {purple indent}
    {*}$say x {italic purple indent}
    {*}$say ")" {purple indent}
    {*}$say ".\n\n" indent
    {*}$say "Some supported operators: " indent
    {*}$say + {purple indent}
    {*}$say ", " indent
    {*}$say - {purple indent}
    {*}$say ", " indent
    {*}$say * {purple indent}
    {*}$say ", " indent
    {*}$say / {purple indent}
    {*}$say ", " indent
    {*}$say % {purple indent}
    {*}$say ", " indent
    {*}$say ** {purple indent}
    {*}$say ".\n" indent
    {*}$say \n
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
    if {[regexp -expanded {
            ((\d{2,4})-\d\d?-\d\d?) # from
            \s*([-+])\s* # op
            (
                (\d+\s*(:?days?|months?))| # add or subtract
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
        my refresh_vars
        my update_combo $EvalCombo $expression
    } on error err {
        {*}$say $err\n red
    }
}
