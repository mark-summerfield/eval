# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
package require config_form
package require lambda 1
package require ref
package require ui

oo::singleton create App {
    variable AnsText
    variable VarTree
    variable ExprCombo
    variable RegexTextCombo
    variable CopyButton
    variable CopyMenu
    variable Vars
}

oo::define App constructor {} {
    ui::wishinit
    tk appname Eval
    Config new ;# we need tk scaling done early
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
    my help
    focus $ExprCombo
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
    set ExprCombo [ttk::combobox .mf.exprcombo \
        -placeholder "enter expr or conversion or date expr or regexp" ]
    set RegexTextCombo [ttk::combobox .mf.regextextcombo \
        -placeholder "enter text for regexp to match"]
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

oo::define App method make_anstext {} {
    const HIGHLIGHT_COLOR yellow
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
    my make_fonts
    set frm [ttk::frame .mf.af]
    set name anstext
    set AnsText [text $frm.$name -wrap word]
    $AnsText configure -font Sans
    $AnsText tag configure indent -lmargin2 [font measure Sans "nn"]
    $AnsText tag configure bold -font Bold
    $AnsText tag configure italic -font Italic
    $AnsText tag configure bolditalic -font BoldItalic
    $AnsText tag configure ul -underline true
    $AnsText tag configure highlight -background $HIGHLIGHT_COLOR
    dict for {key value} $COLOR_FOR_TAG {
        $AnsText tag configure $key -foreground $value
    }
    $AnsText tag configure center -justify center
    $AnsText tag configure right -justify right
    ui::scrollize $frm $name vertical
    .mf.pw add $frm -weight 3
}

oo::define App method make_fonts {} {
    set family [font configure TkDefaultFont -family]
    set size [font configure TkDefaultFont -size]
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
    set cwidth [font measure TkDefaultFont WWW]
    $VarTree column #0 -width [expr {$cwidth * 2}] -stretch true 
    $VarTree column 0 -width $cwidth -stretch false -anchor e
    $VarTree column 1 -width $cwidth -stretch false -anchor e
    $VarTree column 2 -width $cwidth -stretch false -anchor e
    $VarTree heading #0 -text Var
    $VarTree heading 0 -text Dec
    $VarTree heading 1 -text Hex
    $VarTree heading 2 -text U+
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
    pack $ExprCombo -side bottom -fill x
    pack .mf.pw -fill both -expand true
    pack .mf -fill both -expand true
}

oo::define App method make_bindings {} {
    bind $RegexTextCombo <Return> [callback on_eval]
    bind $ExprCombo <Return> [callback on_eval]
    bind . <Alt-o> [callback on_config]
    bind . <Alt-q> [callback on_quit]
    bind . <Escape> [callback on_quit]
    wm protocol . WM_DELETE_WINDOW [callback on_quit]
}

oo::define App method on_config {} {
    set config [Config new]
    set ok [Ref new false]
    set form [ConfigForm new $ok]
    tkwait window [$form form]
}

oo::define App method on_quit {} {
    [Config new] save
    exit
}

# - ([?]|help) → show help text
# - [+*?\\] → regexp
# - (?:meter|km|kilo|kg|second|rad(?:ian)?|deg(?:gree)?|foot|ft|hectare|
#    in(?:ch)?|mi(?:le)?pound|lb|yd|yards?|litres?|stones?|mm|points?)
#   → conversion
# - \d{2,4}-\d\d?-\d\d?\s*[-+]\s*(?:days?months|\d{2,4}-\d\d?-\d\d?) → date
# - [[:alpha:]]\w*\s*= → assignment expr
# - else expr
oo::define App method on_eval {} {
    set eval_txt [$ExprCombo get]
    if {$eval_txt eq "?" | $eval_txt eq "help"} { my help ; return }
    set re_text [$RegexTextCombo get]
}

oo::define App method help {} {
    set say "$AnsText insert end"
    {*}$say Help\n {bold navy center}
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
    {*}$say ".\n\n" indent
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
}
