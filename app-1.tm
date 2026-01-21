# Copyright © 2025 Mark Summerfield. All rights reserved.

package require about_form
package require config
package require config_form
package require help_form
package require lambda 1
package require misc
package require ref
package require scrollutil_tile 2
package require tables_form
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
    variable Words
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
    set Words {}
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
    set say "$AnsText insert end"
    if {$::ASPELL eq {}} {
        {*}$say "Can’t find " brown
        {*}$say aspell maroon
        {*}$say " so can’t spellcheck.\n" brown
    }
    if {!$::HAS_TLS} {
        {*}$say "Can’t find " brown
        {*}$say tls maroon
        {*}$say " so can’t lookup word definitions.\n" brown
    }
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
    ttk::menubutton .mf.ctrl.moreButton -text More -underline 0 -width 7 \
        -compound left -image [ui::icon menu.svg $::ICON_SIZE]
    menu .mf.ctrl.moreButton.menu
    .mf.ctrl.moreButton.menu add command -label Tables… -underline 0 \
        -compound left -command [callback on_tables] -accelerator Ctrl+T \
        -image [ui::icon tables.svg $::MENU_ICON_SIZE]
    .mf.ctrl.moreButton.menu add separator
    .mf.ctrl.moreButton.menu add command -label Config… -underline 0 \
        -compound left -command [callback on_config] \
        -image [ui::icon preferences-system.svg $::MENU_ICON_SIZE]
    .mf.ctrl.moreButton.menu add separator
    .mf.ctrl.moreButton.menu add command -label About -underline 0 \
        -compound left -command [callback on_about] \
        -image [ui::icon about.svg $::MENU_ICON_SIZE]
    .mf.ctrl.moreButton.menu add command -label Help -underline 0 \
        -compound left -command [callback on_help] -accelerator F1 \
        -image [ui::icon help.svg $::MENU_ICON_SIZE]
    .mf.ctrl.moreButton.menu add separator
    .mf.ctrl.moreButton.menu add command -label Quit -underline 0 \
        -compound left -command [callback on_quit] -accelerator Ctrl+Q \
        -image [ui::icon quit.svg $::MENU_ICON_SIZE]
    .mf.ctrl.moreButton configure -menu .mf.ctrl.moreButton.menu
}

oo::define App method make_anstext {} {
    set AnsText [make_text_widget .mf .af]
    .mf.pw add .mf.af -weight 3
}

oo::define App method make_fonts {} {
    set config [Config new]
    set family [$config family]
    set size [$config size]
    foreach name {Mono Sans Bold Italic BoldItalic} {
        catch { font delete $name }
    }
    font create Mono -family CommitMono -size [expr {$size + 1}]
    font create Sans -family $family -size $size
    font create Bold -family $family -size $size -weight bold
    font create Italic -family $family -size $size -slant italic
    font create BoldItalic -family $family -size $size -weight bold \
        -slant italic
}

oo::define App method make_vartree {} {
    set frm [ttk::frame .mf.vf]
    set name vartree
    set sa [scrollutil::scrollarea $frm.sa]
    set VarTree [ttk::treeview $frm.sa.$name -selectmode browse \
        -striped 1 -columns {dec hex uni} -selecttype item]
    $sa setwidget $VarTree
    pack $sa -fill both -expand 1
    $VarTree column #0 -width [font measure Sans WWW]
    $VarTree column 0 -width [font measure Sans WWWWWW] -anchor e
    $VarTree column 1 -width [font measure Sans WWWW] -anchor e
    $VarTree column 2 -width [font measure Sans WW] -anchor center
    $VarTree heading #0 -text Var
    $VarTree heading 0 -text Dec
    $VarTree heading 1 -text Hex
    $VarTree heading 2 -text Uni
    .mf.pw add $frm -weight 1
}

oo::define App method make_layout {} {
    const opts "-pady 3 -padx 3"
    pack .mf.ctrl.copyButton -side left {*}$opts
    pack [ttk::frame .mf.ctrl.pad] -side left -fill x -expand 1 {*}$opts
    pack .mf.ctrl.moreButton -side right {*}$opts
    pack .mf.ctrl -side bottom -fill x
    pack $RegexTextCombo -side bottom -fill x {*}$opts
    pack $EvalCombo -side bottom -fill x {*}$opts
    pack .mf.pw -fill both -expand 1
    pack .mf -fill both -expand 1
}

oo::define App method make_bindings {} {
    bind $VarTree <<TreeviewSelect>> [callback on_tree_click]
    bind $RegexTextCombo <Return> [callback on_eval]
    bind $EvalCombo <Return> [callback on_eval]
    bind . <F1> [callback on_help]
    bind . <Alt-a> [callback on_about]
    bind . <Alt-c> {ui::popup_menu .mf.ctrl.copyButton.menu \
                    .mf.ctrl.copyButton}
    bind . <Alt-e> {focus .mf.exprcombo}
    bind . <Alt-m> {ui::popup_menu .mf.ctrl.moreButton.menu \
                    .mf.ctrl.moreButton}
    bind . <Control-q> [callback on_quit]
    bind . <Control-t> [callback on_tables]
    bind . <Escape> [callback on_quit]
    wm protocol . WM_DELETE_WINDOW [callback on_quit]
}

oo::define App method on_tables {} { TablesForm show }

oo::define App method on_config {} {
    set config [Config new]
    set ok [Ref new 0]
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
            set uni [format %c $value]
        }
        set fmt [expr {[string is integer $value] ? "%Ld" : "%Lg"}]
        $VarTree insert {} end -text $name \
            -values [list [format $fmt $value] $hex $uni]
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
