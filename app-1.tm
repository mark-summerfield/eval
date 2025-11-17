# Copyright © 2025 Mark Summerfield. All rights reserved.

package require about_form
package require config
package require config_form
package require lambda 1
package require ref
package require ui
package require units 2

oo::singleton create App {
    variable AnsText
    variable VarTree
    variable EvalCombo
    variable RegexTextCombo
    variable CopyButton
    variable CopyMenu
    variable Vars
    variable NextName
}

oo::define App constructor {} {
    ui::wishinit
    tk appname Eval
    Config new ;# we need tk scaling done early
    my make_fonts
    set Vars [dict create pi [expr {acos(-1)}]]
    set NextName A
    my make_ui
}

oo::define App method show {} {
    wm deiconify .
    set config [Config new]
    wm geometry . [$config geometry]
    raise .
    update
    after idle [callback on_startup]
}

oo::define App method on_startup {} {
    .mf.pw sashpos 0 [expr {[winfo width .] / 2}]
    my do_help
    my refresh_vars
    focus $EvalCombo
}

oo::define App method make_ui {} {
    my prepare_ui
    my make_widgets
    my make_layout
    my make_bindings
}

oo::define App method prepare_ui {} {
    wm title . [tk appname]
    wm iconname . [tk appname]
    wm iconphoto . -default [ui::icon icon.svg]
}

oo::define App method make_widgets {} {
    set config [Config new]
    ttk::frame .mf
    ttk::panedwindow .mf.pw -orient horizontal
    my make_anstext
    my make_vartree
    set EvalCombo [ttk::combobox .mf.exprcombo -font Sans \
        -placeholder "enter expr or conversion or date expr or regexp" ]
    set RegexTextCombo [ttk::combobox .mf.regextextcombo -font Sans \
        -placeholder "enter text for regexp to match"]
    if {[set re_txt [$config lastregexptext]] ne ""} {
        my prepare_combo $RegexTextCombo $re_txt
    }
    if {[set eval_txt [$config lasteval]] ne ""} {
        my prepare_combo $EvalCombo $eval_txt
    }
    ttk::frame .mf.ctrl
    set CopyButton [ttk::menubutton .mf.ctrl.copyButton -text Copy \
        -underline 0 -width 7 -compound left \
        -image [ui::icon edit-copy.svg $::ICON_SIZE]]
    set CopyMenu [menu .mf.ctrl.copyButton.menu]
    ttk::button .mf.ctrl.optionButton -text Options… -underline 0 \
        -command [callback on_config] -width 7 -compound left \
        -image [ui::icon preferences-system.svg $::ICON_SIZE]
    ttk::button .mf.ctrl.aboutButton -text About -underline 0 \
        -command [callback on_about] -width 7 -compound left \
        -image [ui::icon about.svg $::ICON_SIZE]
    ttk::button .mf.ctrl.quitButton -text Quit -underline 0 \
        -command [callback on_quit] -width 7 -compound left \
        -image [ui::icon quit.svg $::ICON_SIZE]
}

oo::define App method prepare_combo {combo txt} {
    $combo configure -values [list $txt]
    $combo set $txt
    $combo selection range 0 end
    ui::apply_edit_bindings $combo
}

oo::define App method make_anstext {} {
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
    set frm [ttk::frame .mf.af]
    set name anstext
    set AnsText [text $frm.$name -wrap word]
    $AnsText configure -font Sans
    $AnsText tag configure indent -lmargin2 [font measure Sans "nn"]
    $AnsText tag configure bold -font Bold
    $AnsText tag configure italic -font Italic
    $AnsText tag configure bolditalic -font BoldItalic
    $AnsText tag configure ul -underline true
    $AnsText tag configure highlight -background yellow
    dict for {key value} $COLOR_FOR_TAG {
        $AnsText tag configure $key -foreground $value
    }
    $AnsText tag configure center -justify center
    $AnsText tag configure right -justify right
    ui::scrollize $frm $name vertical
    .mf.pw add $frm -weight 3
}

oo::define App method make_fonts {} {
    set config [Config new]
    set family [$config family]
    set size [$config size]
    foreach name {Sans Bold Italic BoldItalic} {
        catch { font delete $name }
    }
    font create Sans -family $family -size $size
    font create Bold -family $family -size $size -weight bold
    font create Italic -family $family -size $size -slant italic
    font create BoldItalic -family $family -size $size -weight bold \
        -slant italic
}

oo::define App method make_vartree {} {
    set frm [ttk::frame .mf.vf]
    set name vartree
    set VarTree [ttk::treeview $frm.$name -selectmode browse -striped true \
        -columns {dec hex uni}]
    $VarTree column #0 -width [font measure Sans WWW]
    $VarTree column 0 -width [font measure Sans WWWWWW] -anchor e
    $VarTree column 1 -width [font measure Sans WWWW] -anchor e
    $VarTree column 2 -width [font measure Sans WW] -anchor center
    $VarTree heading #0 -text Var
    $VarTree heading 0 -text Dec
    $VarTree heading 1 -text Hex
    $VarTree heading 2 -text Uni
    ui::scrollize $frm $name both
    .mf.pw add $frm -weight 1
}

oo::define App method make_layout {} {
    const opts "-pady 3 -padx 3"
    pack .mf.ctrl.copyButton -side left {*}$opts
    pack [ttk::frame .mf.ctrl.pad] -side left -fill x -expand true {*}$opts
    pack .mf.ctrl.optionButton -side left {*}$opts
    pack .mf.ctrl.aboutButton -side left {*}$opts
    pack .mf.ctrl.quitButton -side left {*}$opts
    pack .mf.ctrl -side bottom -fill x
    pack $RegexTextCombo -side bottom -fill x {*}$opts
    pack $EvalCombo -side bottom -fill x {*}$opts
    pack .mf.pw -fill both -expand true
    pack .mf -fill both -expand true
}

oo::define App method make_bindings {} {
    bind $RegexTextCombo <Return> [callback on_eval]
    bind $EvalCombo <Return> [callback on_eval]
    bind . <Alt-a> [callback on_about]
    bind . <Alt-c> {
        tk_popup .mf.ctrl.copyButton.menu \
            [expr {[winfo rootx .mf.ctrl.copyButton]}] \
            [expr {[winfo rooty .mf.ctrl.copyButton] + \
                   [winfo height .mf.ctrl.copyButton]}]
    }
    bind . <Alt-o> [callback on_config]
    bind . <Alt-q> [callback on_quit]
    bind . <Escape> [callback on_quit]
    wm protocol . WM_DELETE_WINDOW [callback on_quit]
}

oo::define App method on_config {} {
    set config [Config new]
    set ok [Ref new false]
    set family [$config family]
    set size [$config size]
    set form [ConfigForm new $ok]
    tkwait window [$form form]
    if {[$ok get]} {
        if {$family ne [$config family] || $size != [$config size]} {
            my make_fonts
        }
    }
}

oo::define App method on_about {} {
    AboutForm new "A calculator-evaluator" \
        https://github.com/mark-summerfield/eval
}

oo::define App method on_quit {} {
    [Config new] save [$EvalCombo get] [$RegexTextCombo get]
    exit
}

oo::define App method on_eval {} {
    set eval_txt [string trim [$EvalCombo get]]
    if {$eval_txt eq ""} { return }
    if {$eval_txt eq "?" | $eval_txt eq "help"} {
        my do_help
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
    $AnsText see end
}

oo::define App method do_help {} {
    set say "$AnsText insert end"
    {*}$say Help\n {bold magenta center}
    {*}$say "Enter one of the following:\n" indent
    {*}$say "Help: " {green italic indent}
    {*}$say ? {blue indent}
    {*}$say " or " indent
    {*}$say help {blue indent}
    {*}$say " to show this help text.\n" indent
    {*}$say Expression {green italic indent}
    {*}$say ", e.g., " indent
    {*}$say "rand() * 5" {blue indent}
    {*}$say " or " indent
    {*}$say "19 / 7" {blue indent}
    {*}$say ".\n" indent
    {*}$say "Assignment expression" {green italic indent}
    {*}$say ", e.g., " indent
    {*}$say "a = 14 ** 2" {blue indent}
    {*}$say ".\n" indent
    {*}$say "Tcl regexp" {green italic indent}
    {*}$say " (and text for the regexp to match), e.g., " indent
    {*}$say "(\\w+)\\s*=\\s*(.*)" {blue indent}
    {*}$say ", and, e.g., " indent
    {*}$say "width = 17" {blue indent}
    {*}$say ".\n" indent
    {*}$say Conversion {green italic indent}
    {*}$say ", e.g., " indent
    {*}$say "69kg to stone" {blue indent}
    {*}$say " (the 'to' is optional).\n" indent
    {*}$say "Date expression" {green italic indent}
    {*}$say ", e.g., " indent
    {*}$say "25-11-14 + 120 days" {blue indent}
    {*}$say " or " indent
    {*}$say "25-11-14 - 25-7-19" {blue indent}
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

oo::define App method update_combo {combo value} {
    set values [$combo cget -values]
    if {$value ni $values} {
        lappend values $value
        $combo configure -values $values
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
                set ans [clock add $from {*}"$op$by_or_end"]
                set to [clock format $ans -format %Y-%m-%d]
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
    my evaluate $name $expression
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
        set ans [expr $expression]
        dict set Vars $name $ans
        {*}$say $name {blue indent}
        {*}$say " = " {green indent}
        {*}$say [format %Lg\n $ans] {blue indent}
        my refresh_vars
        my update_combo $EvalCombo $expression
    } on error err {
        {*}$say $err\n red
    }
}

oo::define App method refresh_vars {} {
    my refresh_vartree
    my refresh_copymenu
}

oo::define App method refresh_vartree {} {
    $VarTree delete [$VarTree children {}]
    foreach name [lsort -dictionary [dict keys $Vars]] {
        set value [dict get $Vars $name]
        set hex ""
        set uni ""
        if {[string is integer $value] && $value > 0 && $value < 0x10FFFF} {
            set hex [format %X $value]
            set uni [format %c $value]
        }
        $VarTree insert {} end -text $name \
            -values "[format %Lg $value] $hex $uni"
    }
}

oo::define App method refresh_copymenu {} {
    $CopyMenu delete 0 end
    set seen [dict create]
    set names [lrange [dict keys $Vars] end-20 end]
    foreach name [lsort -dictionary $names] {
        set value [dict get $Vars $name]
        set ul ""
        set c [string toupper [string index $name 0]]
        if {![dict exists $seen $c]} {
            dict set seen $c ""
            set ul 0
        } else {
            set c [string toupper [string index $name 1]]
            if {![dict exists $seen $c]} {
                dict set seen $c ""
                set ul 1
            }
        }
        $CopyMenu add command -command [callback on_copy $value] \
            -label "$name  [format %Lg $value]" -underline $ul
    }
}

oo::define App method on_copy value {
    clipboard clear
    clipboard append -format STRING -type STRING $value
}

oo::define App method next_name {} {
    set name $NextName
    set NextName [incr_str $NextName]
    return $name
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
