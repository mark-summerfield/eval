# Copyright © 2025 Mark Summerfield. All rights reserved.

package require inifile
package require util

# Also handles tk scaling
oo::singleton create Config {
    variable Filename
    variable Blinking
    variable Geometry
    variable FontFamily
    variable FontSize
    variable LastEvals
    variable LastRegexpText
}

oo::define Config constructor {} {
    set Filename [util::get_ini_filename]
    set Blinking 1
    set Geometry ""
    set FontFamily [font configure TkDefaultFont -family]
    set FontSize [font configure TkDefaultFont -size]
    set LastEvals [list]
    set LastRegexpText ""
    if {[file exists $Filename] && [file size $Filename]} {
        set ini [ini::open $Filename -encoding utf-8 r]
        try {
            tk scaling [ini::value $ini General Scale 1.0]
            if {![set Blinking [ini::value $ini General Blinking \
                    $Blinking]]} {
                option add *insertOffTime 0
                ttk::style configure . -insertofftime 0
            }
            set Geometry [ini::value $ini General Geometry $Geometry]
            set FontFamily [ini::value $ini General FontFamily $FontFamily]
            set FontSize [ini::value $ini General FontSize $FontSize]
            catch {
                foreach i [lseq 1 9] {
                    if {[set an_eval [ini::value $ini LastEvals \
                            Eval$i ""]] ne ""} {
                        lappend LastEvals $an_eval
                    }
                }
            }
            set LastRegexpText [ini::value $ini General LastRegexpText \
                $LastRegexpText]
        } on error err {
            puts "invalid config in '$Filename'; using defaults: $err"
        } finally {
            ini::close $ini
        }
    }
}

oo::define Config method save {lastevals re_txt} {
    set ini [ini::open $Filename -encoding utf-8 w]
    try {
        ini::set $ini General Scale [tk scaling]
        ini::set $ini General Blinking [my blinking]
        ini::set $ini General Geometry [wm geometry .]
        ini::set $ini General FontFamily [my family]
        ini::set $ini General FontSize [my size]
        set i 0
        foreach an_eval [lrange $lastevals 0 8] {
            ini::set $ini LastEvals Eval[incr i] $an_eval
        }
        ini::set $ini General LastRegexpText $re_txt
        ini::commit $ini
    } finally {
        ini::close $ini
    }
}

oo::define Config method filename {} { return $Filename }
oo::define Config method set_filename filename { set Filename $filename }

oo::define Config method blinking {} { return $Blinking }
oo::define Config method set_blinking blinking { set Blinking $blinking }

oo::define Config method geometry {} { return $Geometry }
oo::define Config method set_geometry geometry { set Geometry $geometry }

oo::define Config method size {} { return $FontSize }
oo::define Config method set_size size { set FontSize $size }

oo::define Config method family {} { return $FontFamily }
oo::define Config method set_family family { set FontFamily $family }

oo::define Config method lastevals {} { return $LastEvals }
oo::define Config method set_lastevals lastevals {
    set LastEvals $lastevals
}

oo::define Config method lastregexptext {} { return $LastRegexpText }
oo::define Config method set_lastregexptext lastregexptext {
    set LastRegexpText $lastregexptext
}

oo::define Config method to_string {} {
    return "Config filename=$Filename blinking=$Blinking\
        scaling=[tk scaling] geometry=$Geometry fontfamily=$FontFamily\
        fontsize=$FontSize lastfilename=[my lastfilename]"
}
