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

oo::define HelpForm method populate {} {
    set w ".help_form.mf.hf.txt insert end"
    {*}$w Eval {navy bold indent}
    {*}$w " supports the following actions:\n" indent
    {*}$w "• Expressions" {navy italic indent}
    {*}$w ", e.g., " indent
    {*}$w "(2 ** 32) - 1" {blue indent}
    {*}$w ", " indent
    {*}$w "19. / 7" {blue indent}
    {*}$w ".\n" indent
    {*}$w "• Assignment expressions" {navy italic indent}
    {*}$w ", e.g., " indent
    {*}$w "r = int(rand()*6) + 1" {blue indent}
    {*}$w ".\n" indent
    {*}$w "• Tcl regexps" {navy italic indent}
    {*}$w " (and text for the regexp to match), e.g., " indent
    {*}$w "(\\w+)\\s*=\\s*(.*)" {blue indent}
    {*}$w ", and, e.g., " indent
    {*}$w "width = 17" {blue indent}
    {*}$w ".\n" indent
    {*}$w "• Conversions" {navy italic indent}
    {*}$w ", e.g., " indent
    {*}$w "69kg to stone" {blue indent}
    {*}$w " (the 'to' is optional).\n" indent
    {*}$w "• Date expressions" {navy italic indent}
    {*}$w ", e.g., " indent
    {*}$w "25-11-14 +120 days" {blue indent}
    {*}$w " or " indent
    {*}$w "25-11-14 - 25-7-19" {blue indent}
    {*}$w " (using YYYY-MM-DD or YY-MM-DD format).\n" indent
    {*}$w "• Delete a variable: " {navy italic indent}
    {*}$w "enter " indent
    {*}$w "varname" {indent blue italic}
    {*}$w "=" {indent blue}
    {*}$w .\n indent
    {*}$w "• Clear: " {navy italic indent}
    {*}$w "enter " indent
    {*}$w "cls" {indent blue italic}
    {*}$w " or " indent
    {*}$w "clear" {indent blue italic}
    {*}$w ".\nPress " indent
    {*}$w Return {blue bold indent}
    {*}$w " to perform action.\n\n" indent
    {*}$w "Functions: " indent
    {*}$w abs( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w acos( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w asin( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w atan( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w atan2( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w ceil( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w cos( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w cosh( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w exp( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w floor( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w fmod( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w hypot( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ", " {purple indent}
    {*}$w y {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w log( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w log10( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w pow( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ", " {purple indent}
    {*}$w y {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w rand() {purple indent}
    {*}$w ", " indent
    {*}$w round( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w sin( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w sinh( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w sqrt( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w tan( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ", " indent
    {*}$w tanh( {purple indent}
    {*}$w x {italic purple indent}
    {*}$w ")" {purple indent}
    {*}$w ".\n\n" indent
    {*}$w "Operators: " indent
    {*}$w + {purple indent}
    {*}$w ", " indent
    {*}$w - {purple indent}
    {*}$w ", " indent
    {*}$w * {purple indent}
    {*}$w ", " indent
    {*}$w / {purple indent}
    {*}$w ", " indent
    {*}$w % {purple indent}
    {*}$w ", " indent
    {*}$w ** {purple indent}
    {*}$w ".\n\n" indent
    {*}$w "Keypresses:\n" indent
    {*}$w "• <Escape>" {blue indent}
    {*}$w " quit.\n" indent
    {*}$w "• <Alt-A>" {blue indent}
    {*}$w " select all.\n" indent
    {*}$w "• <Alt-E>" {blue indent}
    {*}$w " move focus to expression entry." indent
}
