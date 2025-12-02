# Copyright © 2025 Mark Summerfield. All rights reserved.

package require about_form
package require config
package require config_form
package require help_form
package require lambda 1
package require misc
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
    variable VarsList
    variable NextName
}

package require app_eval

oo::define App constructor {} {
    ui::wishinit
    tk appname Eval
    Config new ;# we need tk scaling done early
    my make_fonts
    set Vars [dict create pi [expr {acos(-1)}]]
    set VarsList [list]
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
    my refresh_vars
    focus $EvalCombo
    $EvalCombo selection range 0 end
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
    wm minsize . 640 300
}

oo::define App method make_widgets {} {
    set config [Config new]
    ttk::frame .mf
    ttk::panedwindow .mf.pw -orient horizontal
    my make_anstext
    my make_vartree
    set values [$config lastevals]
    set EvalCombo [ttk::combobox .mf.exprcombo -font Sans \
        -placeholder "enter expr or conversion or date expr or\
        regexp (Alt+E for focus)" -values $values]
    if {[llength $values]} {
        $EvalCombo set [lindex $values 0]
        $EvalCombo selection range 0 end
    }
    ui::apply_edit_bindings $EvalCombo
    set RegexTextCombo [ttk::combobox .mf.regextextcombo -font Sans \
        -placeholder "enter text for regexp to match"]
    if {[set re_txt [$config lastregexptext]] ne ""} {
        $RegexTextCombo configure -values [list $re_txt]
        $RegexTextCombo set $re_txt
        $RegexTextCombo selection range 0 end
        ui::apply_edit_bindings $RegexTextCombo
    }
    ttk::frame .mf.ctrl
    set CopyButton [ttk::menubutton .mf.ctrl.copyButton -text Copy \
        -underline 0 -width 7 -compound left \
        -image [ui::icon edit-copy.svg $::ICON_SIZE]]
    set CopyMenu [menu .mf.ctrl.copyButton.menu]
    ttk::button .mf.ctrl.optionButton -text Options… -underline 0 \
        -command [callback on_config] -width 7 -compound left \
        -image [ui::icon preferences-system.svg $::ICON_SIZE]
    ttk::button .mf.ctrl.helpButton -text Help -underline 0 \
        -command [callback on_help] -width 7 -compound left \
        -image [ui::icon about.svg $::ICON_SIZE]
    ttk::button .mf.ctrl.aboutButton -text About -underline 0 \
        -command [callback on_about] -width 7 -compound left \
        -image [ui::icon about.svg $::ICON_SIZE]
    ttk::button .mf.ctrl.quitButton -text Quit -underline 0 \
        -command [callback on_quit] -width 7 -compound left \
        -image [ui::icon quit.svg $::ICON_SIZE]
}

oo::define App method make_anstext {} {
    set AnsText [make_text_widget .mf .af]
    .mf.pw add .mf.af -weight 3
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
        -columns {dec hex uni} -selecttype item]
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
    pack .mf.ctrl.helpButton -side left {*}$opts
    pack .mf.ctrl.aboutButton -side left {*}$opts
    pack .mf.ctrl.quitButton -side left {*}$opts
    pack .mf.ctrl -side bottom -fill x
    pack $RegexTextCombo -side bottom -fill x {*}$opts
    pack $EvalCombo -side bottom -fill x {*}$opts
    pack .mf.pw -fill both -expand true
    pack .mf -fill both -expand true
}

oo::define App method make_bindings {} {
    bind $VarTree <<TreeviewSelect>> [callback on_tree_click]
    bind $RegexTextCombo <Return> [callback on_eval]
    bind $EvalCombo <Return> [callback on_eval]
    bind . <F1> [callback on_help]
    bind . <Alt-a> [callback on_about]
    bind . <Alt-c> {
        tk_popup .mf.ctrl.copyButton.menu \
            [expr {[winfo rootx .mf.ctrl.copyButton]}] \
            [expr {[winfo rooty .mf.ctrl.copyButton] + \
                   [winfo height .mf.ctrl.copyButton]}]
    }
    bind . <Alt-e> {focus .mf.exprcombo}
    bind . <Alt-h> [callback on_help]
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

oo::define App method on_help {} { HelpForm show }

oo::define App method on_quit {} {
    [Config new] save [$EvalCombo cget -values] [$RegexTextCombo get]
    exit
}

oo::define App method update_combo {combo value} {
    set values [$combo cget -values]
    if {[set i [lsearch -exact $values $value]] > -1} {
        set values [lremove $values $i]
    }
    $combo configure -values [linsert $values 0 $value]
}

oo::define App method refresh_vars {} {
    my refresh_vartree
    my refresh_copymenu
}

oo::define App classmethod by_size_alpha {a b} {
    set asize [string length $a]
    set bsize [string length $b]
    if {$asize < $bsize} { return -1 }
    if {$asize > $bsize} { return 1 }
    string compare -nocase $a $b
}

oo::define App method refresh_vartree {} {
    $VarTree delete [$VarTree children {}]
    foreach name [lsort -command [callback by_size_alpha] \
            [dict keys $Vars]] {
        set value [dict get $Vars $name]
        set hex ""
        set uni ""
        if {[string is integer $value] && $value > 0 && $value < 0x10FFFF} {
            set hex [format %X $value]
            set uni [format \\%c $value]
        }
        set fmt [expr {[string is integer $value] ? "%Ld" : "%Lg"}]
        $VarTree insert {} end -text $name \
            -values "[format $fmt $value] $hex $uni"
    }
}

oo::define App method refresh_copymenu {} {
    $CopyMenu delete 0 end
    set seen [dict create]
    foreach name [lrange $VarsList end-10 end] {
        if {[set value [dict getdef $Vars $name ""]] eq ""} { continue }
        set ul ""
        set c [string toupper [string index $name 0]]
        if {![dict exists $seen $c]} {
            dict set seen $c ""
            set ul 0
        } elseif {[string length $name] > 1} {
            set c [string toupper [string index $name 1]]
            if {![dict exists $seen $c]} {
                dict set seen $c ""
                set ul 1
            }
        }
        set fmt [expr {[string is integer $value] ? "%Ld" : "%Lg"}]
        $CopyMenu add command -command [callback on_copy $value] \
            -label "$name  [format $fmt $value]" -underline $ul
    }
}

oo::define App method on_tree_click {} {
    if {[set item [$VarTree focus]] ne ""} {
        if {[set name [$VarTree item $item -text]] ne ""} {
            if {[set value [dict getdef $Vars $name ""]] ne ""} {
                my on_copy $value
            }
        }
    }
}

oo::define App method on_copy value {
    clipboard clear
    clipboard append -format STRING -type STRING $value
}

# Unique names never changed A…Z; resused names AA…AZ
oo::define App method next_name {} {
    set name $NextName
    if {[set NextName [incr_str $NextName]] eq "BA"} {
        set NextName AA
    }
    return $name
}
