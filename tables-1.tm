# Copyright © 2025 Mark Summerfield. All rights reserved.

namespace eval tables {}

package require misc

proc tables::make {} {
    make_text_widget .mf.nb .afrm
    make_text_widget .mf.nb .gfrm
    make_text_widget .mf.nb .nfrm
    .mf.nb add .mf.nb.afrm -text ASCII -underline 0
    .mf.nb add .mf.nb.gfrm -text Greek -underline 0
    .mf.nb add .mf.nb.nfrm -text NATO -underline 0
    tables::MakeAscii
    tables::MakeGreek
    tables::MakeNato
}

proc tables::PrepareTextWidget txt {
    $txt tag configure navy -foreground navy
    $txt tag configure green -foreground green
    $txt tag configure bg0 -background #EAEAEA
    $txt tag configure bg1 -background #FAFAFA
    $txt tag configure sans -font Sans
}

proc tables::MakeAscii {} {
    set txt .mf.nb.afrm.sa.txt
    tables::PrepareTextWidget $txt
    set cw [font measure Mono n]
    $txt configure -font Mono \
        -tabs "[expr {$cw * 2}] center [expr {$cw * 7}] right \
               [expr {$cw * 9}] left [expr {$cw * 14}] left"
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
		 {\\v "VT" "Vertical Tab"}
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

proc tables::MakeGreek {} {
    set txt .mf.nb.gfrm.sa.txt
    tables::PrepareTextWidget $txt
    set cw [font measure Mono n]
    $txt configure -font Mono \
        -tabs "$cw center [expr {$cw * 6}] right \
               [expr {$cw * 8}] center [expr {$cw * 9}] left \
               [expr {$cw * 14}] left"
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

proc tables::MakeNato {} {
    set txt .mf.nb.nfrm.sa.txt
    tables::PrepareTextWidget $txt
    set width [font measure Sans CharlieXX]
    $txt configure -font Sans -tabs "$width left"
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
