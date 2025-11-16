# Copyright © 2025 Mark Summerfield. All rights reserved.

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
}

oo::define App constructor {} {
    ui::wishinit
    tk appname Eval
    Config new ;# we need tk scaling done early
    my make_fonts
    set Vars [dict create]
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
    $CopyButton state disabled
    ttk::button .mf.ctrl.optionButton -text Options… -underline 0 \
        -command [callback on_config] -width 7 -compound left \
        -image [ui::icon preferences-system.svg $::ICON_SIZE]
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
    set cwidth [font measure Sans WWW]
    $VarTree column #0 -width [expr {$cwidth * 2}] -stretch true 
    $VarTree column 0 -width $cwidth -stretch false -anchor e
    $VarTree column 1 -width $cwidth -stretch false -anchor e
    $VarTree column 2 -width $cwidth -stretch false -anchor e
    $VarTree heading #0 -text Var
    $VarTree heading 0 -text Dec
    $VarTree heading 1 -text Hex
    $VarTree heading 2 -text Uni
    ui::scrollize $frm $name both
    .mf.pw add $frm -weight 1
}

oo::define App method make_layout {} {
    const opts "-pady 3 -padx 3"
    pack .mf.ctrl.copyButton -side left
    pack [ttk::frame .mf.ctrl.pad] -side left -fill x -expand true
    pack .mf.ctrl.optionButton -side left
    pack .mf.ctrl.quitButton -side left
    pack .mf.ctrl -side bottom -fill x
    pack $RegexTextCombo -side bottom -fill x
    pack $EvalCombo -side bottom -fill x
    pack .mf.pw -fill both -expand true
    pack .mf -fill both -expand true
}

oo::define App method make_bindings {} {
    bind $RegexTextCombo <Return> [callback on_eval]
    #bind $RegexTextCombo <Control-a> [callback on_select_all %W]
    bind $EvalCombo <Return> [callback on_eval]
    #bind $EvalCombo <Control-a> [callback on_select_all %W]
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

oo::define App method on_quit {} {
    [Config new] save [$EvalCombo get] [$RegexTextCombo get]
    exit
}

oo::define App method on_select_all widget {
    $widget selection range 0 end
    return -code break
}

oo::define App method on_eval {} {
    set eval_txt [string trim [$EvalCombo get]]
    if {$eval_txt eq ""} { return }
    my update_combo $EvalCombo $eval_txt
    if {$eval_txt eq "?" | $eval_txt eq "help"} { my do_help ; return }
    if {[regexp {\d{2,4}-\d\d?-\d\d?} $eval_txt]} {
        my do_date $eval_txt; return
    }
    if {[regexp -expanded {(\m|\d)(meter|km|kilo|kg|second|rad(?:ian)?|
            deg(?:gree)?|foot|ft|hectare|in(?:ch)?|mi(?:le)?pound|lb|
            yd|yards?|litres?|stones?|mm|pt|points?)\M} $eval_txt]} {
        my do_conversion $eval_txt
        return
    }
    if {[regexp {[]^$\{,:?\\|]} $eval_txt]} {
        my do_regexp $eval_txt
        return
    }
    if {[string first = $eval_txt] > -1} {
        my do_assignment $eval_txt
        return
    }
    my do_expression $eval_txt
}

oo::define App method update_combo {combo value} {
    set values [$combo cget -values]
    if {$value ni $values} {
        lappend values $value
        $combo configure -values $values
    }
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
    {*}$say ! {purple indent}
    {*}$say ", " indent
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
        } on error err {
            {*}$say $err\n red
        }
        {*}$say \n
        $AnsText see end
    }
}

oo::define App method do_conversion txt {
    set txt [regsub -nocase {\mto\M} $txt ""]
    set say "$AnsText insert end"
    try {
        {*}$say "conv: " {green indent}
        {*}$say $txt\n {blue indent}
        {*}$say [units::convert {*}$txt]\n {blue indent}
    } on error err {
        {*}$say $err\n red
    }
    {*}$say \n
    $AnsText see end
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
                {*}$say "date diff: " {green indent}
                {*}$say $start {blue indent}
                {*}$say " - " {green indent}
                {*}$say $by_or_end {blue indent}
                {*}$say " → " {green indent}
                {*}$say $days {blue indent}
                {*}$say " days\n" {green indent}
            } else {
                puts "do_date '$start' '$year1' '$op' '$by_or_end' '$year2'" ;# TODO
            }
        } on error err {
            {*}$say $err\n red
        }
    } else {
        {*}$say "invalid date expression\n" red
    }
    $AnsText see end
}

oo::define App method do_assignment txt {
        puts do_assignment ;# TODO
}

oo::define App method do_expression txt {
        puts do_expression ;# TODO
}
