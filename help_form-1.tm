# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require misc
package require ui

oo::singleton create HelpForm { superclass AbstractForm }

oo::define HelpForm classmethod show {} {
    [HelpForm new] show_modeless .help_form.mf.the_button
    focus .help_form.mf.hf.txt
}

oo::define HelpForm constructor {} {
    my make_widgets
    my make_layout
    my make_bindings
    next .help_form [callback on_done]
}

oo::define HelpForm method make_widgets {} {
    tk::toplevel .help_form
    wm minsize .help_form 300 200
    wm title .help_form "[tk appname] — Help"
    ttk::frame .help_form.mf
    make_text_widget .help_form.mf .hf
    .help_form.mf.hf.txt configure -width 40
    my populate
    ttk::button .help_form.mf.the_button -text Close \
        -underline 0 -compound left -command [callback on_done] \
        -image [ui::icon close.svg $::ICON_SIZE]
}

oo::define HelpForm method make_layout {} {
    set opts "-padx 3 -pady 3"
    pack .help_form.mf.the_button -side bottom {*}$opts
    pack .help_form.mf.hf -fill both -expand true {*}$opts
    pack .help_form.mf -fill both -expand true
}

oo::define HelpForm method make_bindings {} {
    bind .help_form <Escape> [callback on_done]
    bind .help_form <Return> [callback on_done]
    bind .help_form <Alt-c> [callback on_done]
}

oo::define HelpForm method on_done {} { my hide }

# Note: hypot() & pow() have a non-breaking space
oo::define HelpForm method populate {} {
    foreach pair {
            {"Actions:\n" {navy}}
            {"• Expression" {purple italic}}
            {", e.g., " {}}
            {"(2 ** 32) - 1" {blue}}
            {", " {}}
            {"19. / 7" {blue}}
            {".\n" {}}
            {"• Assignment expression" {purple italic}}
            {", e.g., " {}}
            {"r = int(rand()*6) + 1" {blue}}
            {".\n" {}}
            {"• Tcl regexp" {purple italic}}
            {" (and text for the regexp to match), e.g., " {}}
            {"(\\w+)\\s*=\\s*(.*)" {blue}}
            {", and, e.g., " {}}
            {"width = 17" {blue}}
            {".\n" {}}
            {"• Conversion" {purple italic}}
            {", e.g., " {}}
            {"69kg to stone" {blue}}
            {" (the 'to' is optional).\n" {}}
            {"• Date expression" {purple italic}}
            {", e.g., " {}}
            {"25-11-14 +120 days" {blue}}
            {" or " {}}
            {"25-11-14 - 25-7-19" {blue}}
            {" (using YYYY-MM-DD or YY-MM-DD format).\n" {}}
            {"• Delete a variable: " {purple italic}}
            {"enter " {}}
            {"varname" {blue italic}}
            {"=" {blue}}
            {.\n {}}
            {"• Clear: " {purple italic}}
            {"enter " {}}
            {"cls" {blue italic}}
            {" or " {}}
            {"clear" {blue italic}}
            {.\n {}}
            {"• Spellcheck" {purple italic}}
            {", enter a word to check, e.g., " {}}
            {"committee" {blue}}
            {".\nPress " {}}
            {<Return> {blue}}
            {" to perform action.\n\n" {}}
            {"Functions:\n" {navy}}
            {"• " {white}}
            {abs( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {acos( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {asin( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {atan( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {atan2( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {ceil( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {cos( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {cosh( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {exp( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {floor( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {fmod( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {hypot( {purple}}
            {x {italic purple}}
            {", " {purple}}
            {y {italic purple}}
            {")" {purple}}
            {", " {}}
            {log( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {log10( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {pow( {purple}}
            {x {italic purple}}
            {", " {purple}}
            {y {italic purple}}
            {")" {purple}}
            {", " {}}
            {rand() {purple}}
            {", " {}}
            {round( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {sin( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {sinh( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {sqrt( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {tan( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {", " {}}
            {tanh( {purple}}
            {x {italic purple}}
            {")" {purple}}
            {".\n\n" {}}
            {"Operators: " {navy}}
            {+ {purple}}
            {", " {}}
            {- {purple}}
            {", " {}}
            {* {purple}}
            {", " {}}
            {/ {purple}}
            {", " {}}
            {% {purple}}
            {", " {}}
            {** {purple}}
            {.\n\n {}}
            {Interactions:\n {navy}}
            {"• <Escape>" {blue}}
            {" quit.\n" {}}
            {"• <F1>" {blue}}
            {" pop-up this help window.\n" {}}
            {"• <Alt-A>" {blue}}
            {" select all.\n" {}}
            {"• <Alt-E>" {blue}}
            {" move focus to expression entry.\n" {}}
            {"• <Click> " {blue}}
            {Var {blue italic}}
            {" copy variable’s value to the clipboard. (Note that the " {}}
            {"Copy" {blue}}
            {" menu provides access to the last ten assigned values)" {}}
            {.\n\n {}}
            {Variables: {navy}}
            {" " {}}
            {A {purple}}
            {" to " {}}
            {Z {purple}}
            {" and user variables are assigned once and not reused\
              (unless explicitly assigned to). Variables " {}}
            {AA {purple}}
            {" to " {}}
            {ZZ {purple}}
            {" are reused as necessary." {}}
        } {
        lassign $pair txt tags
        lappend tags indent
        .help_form.mf.hf.txt insert end $txt $tags
    }
    .help_form.mf.hf.txt configure -state disabled
}
