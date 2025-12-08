# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require misc
package require textedit
package require ui

oo::singleton create HelpForm {
    superclass AbstractForm

    variable Text
}

oo::define HelpForm classmethod show {} {
    set form [HelpForm new]
    $form show_modeless .help_form.mf.the_button
    focus [$form tk_text]
}

oo::define HelpForm constructor {} {
    my make_widgets
    my make_layout
    my make_bindings
    next .help_form [callback on_done]
}

oo::define HelpForm method tk_text {} { $Text tk_text }

oo::define HelpForm method make_widgets {} {
    tk::toplevel .help_form
    wm minsize .help_form 300 200
    wm title .help_form "[tk appname] — Help"
    ttk::frame .help_form.mf
    set Text [TextEdit new .help_form.mf]
    [$Text tk_text] configure -width 40
    my populate
    ttk::button .help_form.mf.the_button -text Close \
        -underline 0 -compound left -command [callback on_done] \
        -image [ui::icon close.svg $::ICON_SIZE]
}

oo::define HelpForm method make_layout {} {
    set opts "-padx 3 -pady 3"
    pack .help_form.mf.the_button -side bottom {*}$opts
    pack [$Text ttk_frame] -fill both -expand true {*}$opts
    pack .help_form.mf -fill both -expand true
}

oo::define HelpForm method make_bindings {} {
    bind .help_form <Escape> [callback on_done]
    bind .help_form <Return> [callback on_done]
    bind .help_form <Alt-c> [callback on_done]
}

oo::define HelpForm method on_done {} { my hide }

oo::define HelpForm method populate {} {
    $Text deserialize [readFile $::APPPATH/help.tktz binary] .tktz 
}
