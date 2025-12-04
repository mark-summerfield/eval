# Copyright © 2025 Mark Summerfield. All rights reserved.

package require abstract_form
package require misc
package require ui

oo::singleton create TablesForm { superclass AbstractForm }

oo::define TablesForm classmethod show {} {
    [TablesForm new] show_modeless .tables_form.mf.the_button
    focus .tables_form.mf.nb
}

oo::define TablesForm constructor {} {
    my make_widgets
    my make_layout
    my make_bindings
    my populate
    next .tables_form [callback on_done]
}

oo::define TablesForm method make_widgets {} {
    tk::toplevel .tables_form
    wm minsize .tables_form 300 200
    wm title .tables_form "[tk appname] — Tables"
    ttk::frame .tables_form.mf
    ttk::notebook .tables_form.mf.nb
    ttk::notebook::enableTraversal .tables_form.mf.nb
    [make_text_widget .tables_form.mf.nb .afrm] configure -width 40
    [make_text_widget .tables_form.mf.nb .gfrm] configure -width 40
    [make_text_widget .tables_form.mf.nb .nfrm] configure -width 40
    .tables_form.mf.nb add .tables_form.mf.nb.afrm -text ASCII -underline 0
    .tables_form.mf.nb add .tables_form.mf.nb.gfrm -text Greek -underline 0
    .tables_form.mf.nb add .tables_form.mf.nb.nfrm -text NATO -underline 0
    ttk::button .tables_form.mf.the_button -text Close \
        -underline 0 -compound left -command [callback on_done] \
        -image [ui::icon close.svg $::ICON_SIZE]
}

oo::define TablesForm method make_layout {} {
    set opts "-padx 3 -pady 3"
    pack .tables_form.mf.the_button -side bottom {*}$opts
    pack .tables_form.mf.nb -fill both -expand true {*}$opts
    pack .tables_form.mf -fill both -expand true
}

oo::define TablesForm method make_bindings {} {
    bind .tables_form <Escape> [callback on_done]
    bind .tables_form <Return> [callback on_done]
    bind .tables_form <Alt-c> [callback on_done]
}

oo::define TablesForm method on_done {} { my hide }

oo::define TablesForm method populate {} {
    my populate_ascii
    my populate_greek
    my populate_nato
}

oo::define TablesForm method PrepareTextWidget txt {
    $txt tag configure navy -foreground navy
    $txt tag configure green -foreground green
    $txt tag configure bg0 -background #EAEAEA
    $txt tag configure bg1 -background #FAFAFA
    $txt tag configure sans -font Sans
    # TODO compute & return n-width for use with -tabs
}

oo::define TablesForm method populate_ascii {} {
    set txt .tables_form.mf.nb.afrm.txt
    my PrepareTextWidget $txt
    $txt configure -tabs {2m center 15m right 20m left 32m left} -font Mono
    set flip 0
    set cp -1
    foreach row {{"" NUL Null}
                 {"" SOH "Start of Header"}
		 {"" "STX" "Start of Text"}
		 {"" "ETX" "End of Text"}
		 {"" "EOT" "End of Transmission"}
		 {"" "ENQ" "Enquiry"}
		 {"" "ACK" "Acknowledge"}
		 {\\a "BEL" "Bell"}
		 {\\b "BS" "Backspace"}
		 {\\t "HT" "Horizontal Tab"}
		 {\\n "LF" "Line Feed"}
		 {\\t "VT" "Vertical Tab"}
		 {\\f "FF" "Form Feed"}
		 {\\r "CR" "Carriage Return"}
		 {"" "SO" "Shift Out"}
		 {"" "SI" "Shift In"}
		 {"" "DLE" "Data Link Escape"}
		 {"" "DC1" "Device Control 1"}
		 {"" "DC2" "Device Control 2"}
		 {"" "DC3" "Device Control 3"}
		 {"" "DC4" "Device Control 4"}
		 {"" "NAK" "Negative Acknowledge"}
		 {"" "SYN" "Synchronize"}
		 {"" "ETB" "End of Transmission Block"}
		 {"" "CAN" "Cancel"}
		 {"" "EM" "End of Medium"}
		 {"" "SUB" "Substitute"}
		 {"" "ESC" "Escape"}
		 {"" "FS" "File Separator"}
		 {"" "GS" "Group Separator"}
		 {"" "RS" "Record Separator"}
		 {"" "US" "Unit Separator"}
		 {" " "SPC" "Space"}} {
        lassign $row c name desc
        set flip [expr {!$flip}]
        set bg bg$flip
        $txt insert end \t[expr {$c eq "" ? "�" : $c}] "navy $bg"
        $txt insert end \t[format %02X [incr cp]] $bg
        $txt insert end \t$name "navy $bg"
        if {$desc ne ""} { $txt insert end \t$desc "green $bg sans" }
        $txt insert end \n $bg
    }
    foreach cp [lseq 0x21 0xFF] {
        set flip [expr {!$flip}]
        set bg bg$flip
        $txt insert end \t[format %c $cp] "navy $bg"
        $txt insert end \t[format %02X $cp]\n $bg
    }
    $txt mark set insert 1.0
}

oo::define TablesForm method populate_greek {} {
    set txt .tables_form.mf.nb.gfrm.txt
    my PrepareTextWidget $txt
    $txt configure -font Mono \
        -tabs {2m center 15m right 20m center 25m left 35m left}
    set flip 0
    foreach row {{Α α Alpha}
		 {Β β Beta}
		 {Γ γ Gamma}
		 {Δ δ Delta}
		 {Ε ε Epsilon}
		 {Ζ ζ Zeta}
		 {Η η Eta}
		 {Θ θ Theta}
		 {Ι ι Iota}
		 {Κ κ Kappa}
		 {Λ λ Lambda}
		 {Μ μ Mu}
		 {Ν ν Nu}
		 {Ξ ξ Xi}
		 {Ο ο Omicron}
		 {Π π Pi}
		 {Ρ ρ Rho}
		 {Σ σ Sigma}
		 {Τ τ Tau}
		 {Υ υ Upsilon}
		 {Φ φ Phi}
		 {Χ χ Chi}
		 {Ψ ψ Psi}
		 {Ω ω Omega}} {
        lassign $row uc lc name
        set flip [expr {!$flip}]
        set bg bg$flip
        $txt insert end \t$uc "navy $bg"
        $txt insert end \t[format %02X [scan $uc %c]] $bg
        $txt insert end \t$lc "navy $bg"
        $txt insert end \t[format %02X [scan $lc %c]] $bg
        $txt insert end \t$name\n "green $bg sans"
    }
}

oo::define TablesForm method populate_nato {} {
    set txt .tables_form.mf.nb.nfrm.txt
    my PrepareTextWidget $txt
    $txt configure -font Mono -tabs {25m left}
    set words [list Alpha Bravo Charlie Delta Echo Foxtrot Golf Hotel \
               India Juliet Kilo Lima Mike November Oscar Papa Quebec \
               Romeo Sierra Tango Uniform Victor Whiskey X-ray Yankee Zulu]
    set flip 0
    set half [expr {[llength $words] / 2}]
    for {set i 0} {$i < $half} {incr i} {
        set flip [expr {!$flip}]
        set bg bg$flip
        set word1 [lindex $words $i]
        set word2 [lindex $words [expr {$i + $half}]]
        $txt insert end $word1\t$word2\n "navy $bg"
    }
}
