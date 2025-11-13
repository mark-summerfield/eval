# Copyright © 2025 Mark Summerfield. All rights reserved.

package require config
package require config_form
package require lambda 1
package require ref
package require ui

oo::singleton create App {
    variable AnsText
    variable ExprCombo
    variable ExprEntry
}

oo::define App constructor {} {
    ui::wishinit
    tk appname Eval
    Config new ;# we need tk scaling done early
    my make_ui
}

oo::define App method show {} {
    wm deiconify .
    set config [Config new]
    wm geometry . [$config geometry]
    raise .
    update
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
    ttk::frame .mf.ctrl
    # TODO button [&Copy v]
    ttk::button .mf.ctrl.optionButton -text Options… -underline 0 \
        -command [callback on_config] -width 7 -compound left \
        -image [ui::icon preferences-system.svg $::ICON_SIZE]
    ttk::button .mf.ctrl.quitButton -text Quit -underline 0 \
        -command [callback on_quit] -width 7 -compound left \
        -image [ui::icon quit.svg $::ICON_SIZE]
    set frm [ttk::frame .mf.af]
    set name anstext
    set AnsText [text $frm.$name]
    ui::scrollize $frm $name vertical
    set ExprCombo [ttk::combobox .mf.combo \
        -placeholder "enter expression or conversion or regexp" ]
    set ExprEntry [ttk::entry .mf.entry \
        -placeholder "enter text for regexp to match"]
}

oo::define App method make_layout {} {
    const opts "-pady 3 -padx 3"
    # TODO Copy button
    pack [ttk::frame .mf.ctrl.pad] -side left -fill x -expand true
    pack .mf.ctrl.optionButton -side left
    pack .mf.ctrl.quitButton -side left
    pack .mf.ctrl -side top -fill x
    pack $ExprEntry -side bottom -fill x
    pack $ExprCombo -side bottom -fill x
    pack .mf.af -fill both -expand true
    pack .mf -fill both -expand true
}

oo::define App method make_bindings {} {
    bind . <Alt-c> [callback on_config]
    bind . <Alt-q> [callback on_quit]
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
