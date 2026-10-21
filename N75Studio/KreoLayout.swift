// KreoLayout.swift — VGN N75 / Hive 75 physical layout + per-key LED slot map (from kreoctl).
import Foundation

struct KeyDef: Identifiable {
    let id: Int
    let code: String
    let label: String
    let row: Int
    let width: Double   // in key units (1.0 = 1u)
}

enum KreoLayout {
    static let ledsPerColumn = 8
    static func slot(_ col: Int, _ row: Int) -> Int { col * ledsPerColumn + row }

    static let spaceSlots = [slot(3,5), slot(4,5), slot(5,5), slot(6,5), slot(7,5), slot(8,5)]

    /// LED slot indices lit by a key (verified on Hive 75).
    static func ledSlots(_ code: String) -> [Int] {
        if code == "Space" { return spaceSlots }
        guard let (c, r) = colRow[code] else { return [] }
        return [slot(c, r)]
    }

    private static let colRow: [String: (Int, Int)] = [
        "Esc":(0,0),"F1":(1,0),"F2":(2,0),"F3":(3,0),"F4":(4,0),"F5":(5,0),"F6":(6,0),"F7":(7,0),
        "F8":(8,0),"F9":(9,0),"F10":(10,0),"F11":(11,0),"F12":(12,0),"Del":(13,0),
        "Grave":(0,1),"1":(1,1),"2":(2,1),"3":(3,1),"4":(4,1),"5":(5,1),"6":(6,1),"7":(7,1),
        "8":(8,1),"9":(9,1),"0":(10,1),"Minus":(11,1),"Equal":(12,1),"Backspace":(13,1),
        "Tab":(0,2),"Q":(1,2),"W":(2,2),"E":(3,2),"R":(4,2),"T":(5,2),"Y":(6,2),"U":(7,2),
        "I":(8,2),"O":(9,2),"P":(10,2),"LBracket":(11,2),"RBracket":(12,2),"Backslash":(13,2),
        "Ins":(14,2),"PgDn":(15,2),
        "CapsLock":(0,3),"A":(1,3),"S":(2,3),"D":(3,3),"F":(4,3),"G":(5,3),"H":(6,3),"J":(7,3),
        "K":(8,3),"L":(9,3),"Semicolon":(10,3),"Quote":(11,3),"Enter":(13,3),"End":(14,3),"PgUp":(15,3),
        "LShift":(0,4),"Z":(2,4),"X":(3,4),"C":(4,4),"V":(5,4),"B":(6,4),"N":(7,4),"M":(8,4),
        "Comma":(9,4),"Period":(10,4),"Slash":(11,4),"RShift":(13,4),"Up":(14,4),
        "LCtrl":(0,5),"LWin":(1,5),"LAlt":(2,5),"RAlt":(9,5),"Fn":(10,5),"RCtrl":(12,5),
        "Left":(13,5),"Down":(14,5),"Right":(15,5),
    ]

    /// First LED slot for a key (for reactive effects).
    static func ledIndex(_ code: String) -> Int? { ledSlots(code).first }

    /// The 75% layout rows.
    static let keys: [KeyDef] = {
        var k: [KeyDef] = []; var id = 0
        func add(_ code: String, _ label: String, _ row: Int, _ w: Double) {
            k.append(KeyDef(id: id, code: code, label: label, row: row, width: w)); id += 1
        }
        // Row 0
        add("Esc","ESC",0,1); for i in 1...12 { add("F\(i)","F\(i)",0,1) }; add("Del","DEL",0,1); add("Knob","KNOB",0,1.25)
        // Row 1
        add("Grave","~",1,1); for s in ["1","2","3","4","5","6","7","8","9","0"] { add(s,s,1,1) }
        add("Minus","-",1,1); add("Equal","=",1,1); add("Backspace","BACK",1,2); add("Ins","INS",1,1)
        // Row 2
        add("Tab","TAB",2,1.5); for s in ["Q","W","E","R","T","Y","U","I","O","P"] { add(s,s,2,1) }
        add("LBracket","[",2,1); add("RBracket","]",2,1); add("Backslash","\\",2,1.5); add("End","END",2,1)
        // Row 3
        add("CapsLock","CAPS",3,1.75); for s in ["A","S","D","F","G","H","J","K","L"] { add(s,s,3,1) }
        add("Semicolon",";",3,1); add("Quote","'",3,1); add("Enter","ENTER",3,2.25); add("PgUp","PGUP",3,1)
        // Row 4
        add("LShift","SHIFT",4,2.25); for s in ["Z","X","C","V","B","N","M"] { add(s,s,4,1) }
        add("Comma",",",4,1); add("Period",".",4,1); add("Slash","/",4,1)
        add("RShift","SHIFT",4,1.75); add("Up","↑",4,1); add("PgDn","PGDN",4,1)
        // Row 5
        add("LCtrl","CTRL",5,1.25); add("LWin","WIN",5,1.25); add("LAlt","ALT",5,1.25); add("Space","",5,6.25)
        add("RAlt","ALT",5,1); add("Fn","FN",5,1); add("RCtrl","CTRL",5,1)
        add("Left","←",5,1); add("Down","↓",5,1); add("Right","→",5,1)
        return k
    }()

    /// Pack a code→color map into the 384-byte LED buffer (fallback for unset keys).
    static func ledBuffer(colors: [String: RGBColor], fallback: RGBColor) -> [UInt8] {
        var buf = [UInt8](repeating: 0, count: Kreo.totalLEDs * 3)
        for i in 0..<Kreo.totalLEDs { buf[i*3] = UInt8(fallback.r); buf[i*3+1] = UInt8(fallback.g); buf[i*3+2] = UInt8(fallback.b) }
        for (code, c) in colors {
            for s in ledSlots(code) where s < Kreo.totalLEDs {
                buf[s*3] = UInt8(c.r); buf[s*3+1] = UInt8(c.g); buf[s*3+2] = UInt8(c.b)
            }
        }
        return buf
    }
}
