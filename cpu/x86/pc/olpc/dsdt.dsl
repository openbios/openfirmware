/*
 XXX need an entry for the DCON (IRQ 6)
 XXX define the EC somehow (IRQ 3, registers, etc)
 XXX define the lid switch (IRQ 3)
 XXX sort out sleep button vs. power button distinction
 XXX battery device
 VRs
 ac1c..ac1f
 9e00..9e05 p_blk section 4.7.3.5 p 96
 9c2c power control
 Assumes GPIOs mapped at 0x6100
 VR 0x14, 1 or 2 probes UARTS 1,2.  Return 0 for "not present"
 */
DefinitionBlock ("dsdt.aml", "DSDT", 3, "OLPC  ", "XO-1    ", 0x00001000) {
    Name (VERS, Package (0x02) {
        "OLPC XO-1", 
        "$Id$"
    })
    OperationRegion (VSA1, SystemIO, 0xAC1C, 0x04)
    Field (VSA1, WordAcc, NoLock, Preserve) {
        VSA2,   16, 
        VSA3,   16
    }

    Mutex (VSA4, 0x00)

    Method (VSAR, 1, Serialized) {    // VSAR  (index -- resword )
        Name (VRRR, Zero)
        Acquire (VSA4, 0xFFFF)
        Store (0xFC53, VSA2) // Unlock
        Store (Arg0, VSA2)
        Store (VSA3, Local1)
        Release (VSA4)
        Store (Local1, VRRR)
        Return (VRRR)
    }

    Method (VSAW, 2, Serialized) {  // VSAW ( index value -- )
        Acquire (VSA4, 0xFFFF)
        Store (0xFC53, VSA2) // Unlock
        Store (Arg0, VSA2)
        Store (Arg1, VSA3)
        Release (VSA4)
    }

//    Mutex (ECMX, 0x00)

    OperationRegion (UART, SystemIO, 0x03f8, 0x07)

    Field (UART, ByteAcc, NoLock, Preserve)
    {
        UDAT,   8, 
        UAR1,   8, 
        UAR2,   8,
        UAR3,   8,
        UAR4,   8,
        USTA,   8,
        UAR5,   8
    }
    Method (UPUT, 1, NotSerialized)
    {
        While( LEqual (And (USTA, 0x20), Zero) )
        {
            Stall (99)
        }
        Store (Arg0, UDAT)
    }

    Method (UDOT, 1, NotSerialized)
    {
        
        And (ShiftRight (Arg0, 4), 0xF, Local0)
        If (LLess (Local0, 10))
        {
            Add (Local0, 0x30, Local0)  // '0'
        } Else {
            Add (Local0, 0x57, Local0)  // 'a' - 10
        }
        UPUT (Local0)
        
        And (Arg0, 0xF, Local0)
        If (LLess (Local0, 10))
        {
            Add (Local0, 0x30, Local0)  // '0'
        } Else {
            Add (Local0, 0x57, Local0)  // 'a' - 10
        }
        UPUT (Local0)

        UPUT (0x20)
    }

    OperationRegion (ECIX, SystemIO, 0x0381, 0x03)

    Field (ECIX, ByteAcc, NoLock, Preserve)
    {
        EIXH,   8, 
        EIXL,   8, 
        EDAT,   8
    }

    Method (ECRD, 1, NotSerialized)
    {
//        Acquire (ECMX, 5000)
        Store (ShiftRight (Arg0, 0x08), EIXH)
        Store (And (Arg0, 0xFF), EIXL)
//        Sleep (15)
        Stall(255)
        Store (EDAT, Local0)
//        UDOT (Local0)
        Stall(255)
//        Sleep (15)
//        Release (ECMX)
        Return (Local0)
    }

    OperationRegion (ECCP, SystemIO, 0x068, 0x05)

    Field (ECCP, ByteAcc, NoLock, Preserve)
    {
        ECDA,   8,   // 0x68
            ,   8,
            ,   8,
            ,   8,
        ECCM,   8,   // 0x6c
    }

    Method (ECCO, 1, NotSerialized)  // EC Command Out (command)
    {
        Store (1000, Local0)
        While (And (ECCM, 2))  // Wait for IBF == 0
        {
           if (LEqual (Subtract(Local0, One, Local0), Zero))
           {
               Return (One)
           }
           Sleep(1)
        }
        Store (Arg0, ECCM)
        Store (1000, Local0)
        While (LNot (And (ECCM, 2)))  // Wait for IBF != 0
        {
           if (LEqual (Subtract(Local0, One, Local0), Zero))
           {
               Return (2)
           }
           Sleep(1)
        }
        Return (Zero)
    }

    Method (ECRB, 0, NotSerialized)  // EC Read Byte after command -> byte
    {
        Store (200, Local0)
        While (LNot (And (ECCM, 1)))  // Wait for OBF != 0
        {
           If (LEqual (Subtract(Local0, One, Local0), Zero))
           {
               Return (0xffffffff)
           }
           Sleep(1)
        }
        Return (ECDA)
    }

    Method (ECC1, 1, NotSerialized)  // EC Command returning 1 byte
    {
        Store (10, Local0)                     // Ten retries
        While (Subtract(Local0, One, Local0))  // While more tries left
        {
            If (ECCO (Arg0))
            {
                Continue                        // Command timeout
            }
            Store (ECRB (), Local1)
            If (LNotEqual (Local1, 0xffffffff))
            {
                Return (Local1)                 // Success
            }
        }
        Return (Zero)

    }

    Scope (_PR) {
        Processor (CPU0, 0x01, 0x00000000, 0x00) {}
//        Processor (CPU0, 0x01, 0x00009E00, 0x06) {
//            Name (_PCT, Package (0x02) {
//                ResourceTemplate () {
//                    Register (SystemIO, 0x08, 0x00, 0x0000000000009C2C, ,)
//                }, 
//
//                ResourceTemplate () {
//                    Register (SystemIO, 0x08, 0x00, 0x0000000000009C2C, ,)
//                }
//            })
//            // Question: Why have two identical performance states?
//            Name (_PSS, Package (0x02) {
//                Package (0x06) { 0x01B1, 0x03BF, 0x2D, Zero, 0x0D, 0x0D }, 
//                Package (0x06) { 0x01B1, 0x03BF, 0x2D, Zero, 0x0D, 0x0D }
//            })
//            Name (_PPC, Zero)
//        }
    }

    Name (_S0, Package (0x04) { Zero, Zero, Zero, Zero })  // Values for PM1a,b_CNT.SLP_TYP registers
    Name (_S1, Package (0x04) { One, One, Zero, Zero })
    Name (_S3, Package (0x04) { 0x03, 0x03, Zero, Zero })
    Name (_S5, Package (0x04) { 0x05, 0x05, Zero, Zero })
    Name (_SB.ZZY2, Zero)
    Name (ZZY1, Zero)  // Current state - see _SST page 298 for values
    Name (ZZY3, Zero)  // "Already inited" flag
    Name (ZZY4, Zero)  // EBDA base address in bytes
//  Name (ZZY5, Zero)  // Set to EBDA length in bytes - unused
    Name (ZZY6, Zero)  // Set to memory size in Kbytes

    Method (_PTS, 1, NotSerialized) {
// VSAW(0, 0xc)
 Store (Arg0, \_SB.ZZY2) }

//    Method (_GTS, 1, NotSerialized) {  /* VSAW(0, 0xb) */  }  // GoingToSleep
//    Method (_BFS, 1, NotSerialized) {  /* VSAW(0, 0xa) */   }  // Back from sleep

    Method (_WAK, 1, NotSerialized) {  // Arg is the sleeping state
// VSAW(0, 9)
        Store (Zero, \_SB.ZZY2)
        Switch (Arg0) {
            Case (One) {
                Notify (\_SB.PCI0.USB0, Zero)
                Notify (\_SB.PCI0.USB1, Zero)
//                Notify (\_SB.PCI0.SBF0.KBC, Zero)
//                Notify (\_SB.PCI0.SBF0.PS2M, Zero)
            }
            Case (0x03) {
                Notify (\_SB.PCI0, Zero)
            }
        }
        Return (Zero)  /* Success */
    }

    Scope (_GPE) {                          // General Purpose Events

        // pdf p 162 has Notify argument values
        Method (_L00, 0, NotSerialized) {            // Level-triggered event 0
// VSAW(0, 8)
            If (LEqual (ZZY1, One)) {                // no state or working state
//                Notify (\_SB.PCI0.SBF0.KBC, 0x02)
//                Notify (\_SB.PCI0.SBF0.PS2M, 0x02)
                Notify (\_SB.PCI0.SBF0, 0x02)
            }
        }

        // Likely unnecessary
//        Method (_L05, 0, NotSerialized)
//        {
//            // DDD geoderom guards this with If (LEqual (ZZY1, One))
//            Notify (\_SB.PCI0.USB0, 0x02)
//        }

        // XXX probably pointless as power is off
        Method (_L06, 0, NotSerialized) {            // USB event
// VSAW(0, 7)
            If (LEqual (ZZY1, One)) {                // no state or working state
                Notify (\_SB.PCI0.USB0, 0x02)
            }

            Notify (\_SB.PCI0.USB1, 0x02)
        }
        
        Method (_L1E, 0, NotSerialized) {            // Comes from IRQ/PME Mapper bit 6 - LID switch
// VSAW(0, 6)
//            UPUT(0x4C)               // L
//            UPUT(Add(0x30, ZZY1))
            If (LEqual (\_SB.ZZY2, Zero)) {          // Not preparing to sleep
//                If (LLess (ZZY1, 0x02)) {            // no state or working state or waking
                    Notify (\_SB.LIDS, 0x80)         // Request to go to sleep
//                }
            } Else {
                Notify (\_SB.LIDS, 0x02)             // Request to wake up
            }
        }

        Method (_L1F, 0, NotSerialized) {            // Comes from IRQ/PME Mapper bit 7 - SCI
// VSAW(0, 5)
//            UPUT(0x53)               // S

            Store (One, Local0)
            While (Local0)
            {
                Store (ECC1(0x84), Local0)  // Read SCI Queue
//                UDOT (Local0)
                If (And(Local0, 0x40))
                {
                    Notify (\_SB.AC, 0x80)
                }
                If (And(Local0, 0x0e))
                {
                    Notify (\_SB.BATT, 0x80)
                }
            }

//              Notify (\_SB.PCI0, 0x02)                 // Request to wake up from EC
//              Notify (\_SB.AC, 0x80)
//              Notify (\_SB.BATT, 0x80)
//            UPUT(0x54)               // T
        }
    }

    // This is an indicator method - it sets LEDs based on the sleep state
    Scope (_SI) {
        Method (_SST, 1, NotSerialized) {
//            UPUT(0x24)  // $
//            UPUT(Add(0x30, Arg0))
// VSAW(1, Arg0)
// XXX ??? need to set LEDs by doing VR accesses - or probably the EC does it automatically
            Store (Arg0, ZZY1)
        }
    }

    Scope (_SB) {
        Method (_INI, 0, NotSerialized) {
            If (LEqual (ZZY3, One)) {
                Return
            }
            Store (One, ZZY3)

            CreateWordField (^LNKA._PRS, One, IBMA)
            CreateWordField (^LNKB._PRS, One, IBMB)
            CreateWordField (^LNKC._PRS, One, IBMC)
            CreateWordField (^LNKD._PRS, One, IBMD)

            OperationRegion (QQH1, SystemMemory, 0x040E, 0x02)
            Field (QQH1, WordAcc, NoLock, Preserve) {
                QQH2,   16
            }

            Store (QQH2, Local0)   // Memory address 0x40e - EBDA address from BIOS data area
            ShiftLeft (Local0, 0x04, ZZY4)
            OperationRegion (EBDA, SystemMemory, ZZY4, 0x0400)

            Field (EBDA, AnyAcc, NoLock, Preserve) {
                        AccessAs (ByteAcc, 0x00), 
                QQE1,   8, 
                        Offset (0x180), 
                        AccessAs (DWordAcc, 0x00), 
                QQE2,   32
            }

//          Store (QQE1, Local0)
//          Multiply (Local0, 0x0400, ZZY5)  // Unused
            Store (QQE2, ZZY6)
//    VSAW(0, 1)
        }

        OperationRegion (GPIO, SystemIO, 0x1000, 0x0100)
        Field (GPIO, DWordAcc, NoLock, Preserve) {
//                    Offset (0x38), 
//            GLEE,   32
                    Offset (0xA4),
            GHIN,   32,               // High bank Input Invert
                    Offset (0xB0),    // High bank read back
                ,   10, 
            LSWI,   1                 // Lid switch bit
//                  Offset (0xB8),
//          GHEE,   32                // High bank events enable
//                  Offset (0xC0),
//          GHPE,   32,               // High bank posedge enable
//          GHNE,   32,               // High bank negedge enable
//          GHPS,   32,               // High bank posedge status
//          GHNS,   32,               // High bank negedge status
        }

        Device (LNKA) {
            Name (_HID, EisaId ("PNP0C0F"))
            Name (_UID, One)
            Method (_DIS, 0, NotSerialized) { }
            Name (_CRS, ResourceTemplate () { IRQ (Level, ActiveLow, Shared, _Y00) {11} })
            Name (_PRS, ResourceTemplate () { IRQ (Level, ActiveLow, Shared,     ) {11} })
            Name (_STA, 0x09)
        }

        Device (LNKB) {
            Name (_HID, EisaId ("PNP0C0F"))
            Name (_UID, 0x02)
            Method (_DIS, 0, NotSerialized) { }
            Name (_CRS, ResourceTemplate () { IRQ (Level, ActiveLow, Shared, _Y01) {5} })
            Name (_PRS, ResourceTemplate () { IRQ (Level, ActiveLow, Shared,     ) {5} })
            Name (_STA, 0x09)
        }

        Device (LNKC) {
            Name (_HID, EisaId ("PNP0C0F"))
            Name (_UID, 0x03)
            Method (_DIS, 0, NotSerialized) { }
            Name (_CRS, ResourceTemplate () { IRQ (Level, ActiveLow, Shared, _Y02) {14} })
            Name (_PRS, ResourceTemplate () { IRQ (Level, ActiveLow, Shared,     ) {14} })
            Name (_STA, 0x09)
        }

        Device (LNKD) {
            Name (_HID, EisaId ("PNP0C0F"))
            Name (_UID, 0x04)
            Method (_DIS, 0, NotSerialized) { }
            Name (_CRS, ResourceTemplate () { IRQ (Level, ActiveLow, Shared, _Y03) {10} })
            Name (_PRS, ResourceTemplate () { IRQ (Level, ActiveLow, Shared,     ) {10} })
            Name (_STA, 0x09)
        }

        Mutex (ACMX, 0x00)
        Device (AC) {  /* AC adapter */
            Name (_HID, "ACPI0003")
            Name (_PCL, Package (0x01) { _SB })  // Power consumer list - points to main system bus

            Method (_PSR, 0, NotSerialized)
            {
                If (LNot (Acquire (ACMX, 5000)))
                {
//                    UPUT (0x70)  // p
                    Store (ECRD (0xFA40), Local0)
                    Release (ACMX)
                }

                If (And (Local0, One))
                {
                    Return (One)
                }
                Else
                {
                    Return (Zero)
                }
            }

//            Name (_STA, 0x0F)
Method (_STA, 0, NotSerialized) { Return (0x0F) }
        }

        // DDD geoderom has no battery stuff
        Name (BIFP, Package (0x0D)  // Battery info (static)  p 342
        {
            One,           // Power units - 1 : mAh / mA
            0x0ED8,        // Design capacity
            0x0BB8,        // Last Full Charge capacity
            One,           // rechargable
            0x1770,        // Full voltage in mV
            0x01C2,        // warning capacity
            0x0F,          // low capacity
            0x01B3,        // granularity between low and warning
            0x09F6,        // granularity between warning and full
            "NiMH (GP) ",  // Model number
            "",            // serial number
            "NiMH",        // type
            "OLPC "        // OEM info
        })
        Name (BSTP, Package (0x04)  // Battery status (dynamic) p 343
        {
            Zero,          // state - bitmask 1: discharging 2: charging 4: critical
            760,           // current flow
            2910,          // remaining capacity
            23306          // voltage in mV
        })
        Device (BATT)
        {
            Name (_HID, EisaId ("PNP0C0A"))
            Name (_UID, One)
            Name (_PCL, Package (0x01)
            {
                _SB
            })
            Method (_STA, 0, NotSerialized)   // Battery Status
            {
                If (LEqual (ZZY2, 0x03))
                {
                    Return (0x0F)
                }

                If (LNot (Acquire (ACMX, 5000)))
                {
//                    UPUT (0x73)  // s
                    Store (ECRD (0xFAA4), Local0)
                    Release (ACMX)
                }

                If (And (Local0, One))  // ECRD(0xfaa4) & 0x01 => Battery inserted
                {
                    Return (0x1F)
                }
                Else
                {
                    Return (0x0F)
                }
            }

            Method (_BIF, 0, NotSerialized)         // Battery Info
            {
                If (LNot (Acquire (ACMX, 5000)))
                {
//                    UPUT (0x69)  // i
                    Store (ECRD (0xFB5F), Local0)
                    Store (ECRD (0xF929), Local1)
                    Switch (Local0)
                    {
                        Case (0x11)
                        {
//                            UPUT (0x42)  // B
                            Store (3800, Index (BIFP, One))
                            Store (3000, Index (BIFP, 2))
                            Store (6000, Index (BIFP, 0x04))
                            Multiply (Local1, 30, Local1)
                            Store (Local1, Index (BIFP, 5))
                            Store (15, Index (BIFP, 6))
                            Store (Subtract (Local1, 15), Index (BIFP, 7))
                            Store (Subtract (3000, Local1), Index (BIFP, 8))
                            Store ("NiMH (GP) ", Index (BIFP, 9))
                            Store ("", Index (BIFP, 10))
                            Store ("GoldPeak ", Index (BIFP, 0x0C))
//                            UPUT (0x62)  // b
                        }
                        Case (0x12)
                        {
//                            UPUT (0x44)  // D
                            Store (3000, Index (BIFP, One))
                            Store (2800, Index (BIFP, 2))
                            Store (6000, Index (BIFP, 4))
                            Multiply (Local1, 28, Local1)
                            Store (Local1, Index (BIFP, 5))
                            Store (14, Index (BIFP, 6))
                            Store (Subtract (Local1, 14), Index (BIFP, 7))
                            Store (Subtract (2800, Local1), Index (BIFP, 8))
                            Store ("LiFePO4 (GP) ", Index (BIFP, 9))
                            Store ("", Index (BIFP, 10))
                            Store ("GoldPeak ", Index (BIFP, 0x0C))
//                            UPUT (0x64)  // d
                        }
                        Case (0x22)
                        {
//                            UPUT (0x43)  // C
                            Store (3550, Index (BIFP, One))
                            Store (3100, Index (BIFP, 2))
                            Store (6500, Index (BIFP, 4))
                            Multiply (Local1, 31, Local1)
                            Store (Local1, Index (BIFP, 5))
                            Store (15, Index (BIFP, 6))
                            Store (Subtract (Local1, 15), Index (BIFP, 7))
                            Store (Subtract (3100, Local1), Index (BIFP, 8))
                            Store ("LiFePO4 (BYD) ", Index (BIFP, 9))
                            Store ("", Index (BIFP, 10))
                            Store ("BYD ", Index (BIFP, 0x0C))
//                            UPUT (0x63)  // c
                        }
                    }

//                    UPUT (0x49)  // I
                    If (And (ECRD (0xFAA5), 8))
                    {
                        Store ("NiMH", Index (BIFP, 11))
                    }
                    Else
                    {
//x                        Store ("LiON", Index (BIFP, 11))
                        Store ("LiFePO4", Index (BIFP, 11))
                    }

//x                    Store ("OLPC ", Index (BIFP, 0x0C))
                    Release (ACMX)
                }

                Return (BIFP)
            }

            Method (_BST, 0, NotSerialized)
            {
                If (LNot (Acquire (ACMX, 5000)))
                {
//                    UPUT (0x74)  // t
                    If (And (ECRD (0xFAA5), One))
                    {
                        Store (0x02, Local1)  // charging
                    }
                    Else
                    {
                        Store (One, Local1)  // discharging
                    }

                    Sleep (15)
                    Store (ECRD (0xF910), Local0)
                    If (LLess (Local0, 15))
                    {
                        Or (Local1, 4, Local1)  // critical
                    }

                    Store (Local1, Index (BSTP, Zero))
                    Sleep (15)

                    Switch (ECRD (0xFB5F))
                    {
                        Case (0x11)
                        {
                            Store (760, Index (BSTP, One))
                            Multiply (Local0, 30, Local2)
                        }
                        Case (0x22)
                        {
                            Store (1500, Index (BSTP, One))
                            Multiply (Local0, 31, Local2)
                        }
                        Case (0x12)
                        {
                            Store (1500, Index (BSTP, One))
                            Multiply (Local0, 28, Local2)
                        }
                    }

                    Store (Local2, Index (BSTP, 2))
                    Release (ACMX)
                }

                Return (BSTP)
            }
        }

// XXX ??? Need battery device with static and dynamic info

        Device (LIDS) {
            Name (_HID, EisaId ("PNP0C0D"))
            Name (_PRW, Package (0x02) {  0x1e, 0x03 })            // Event 1e, wakes from S3
            Method (_INI, 0, NotSerialized) {
                Store (0x400, GHIN)               // Turn on invert to see falling edge
            }
            Method (_LID, 0, NotSerialized) {
                // The expected state is LSWI == 1, because the inverter is either
                // on or off depending on the previous state.
                // If LSWI == 0, it means that the switch changed values then
                // changed back to the previous state.
//                UPUT (0x6c)                       // l
                If (LSWI) {
                    If (And(GHIN, 0x400))
                    {                                     // Inverted, became closed
//                        UPUT (0x30)
                        Store (0x4000000, GHIN)           // Turn on invert to see falling edge
                        Store (Zero, Local0)
                    } Else {                              // Not inverted, became open
//                        UPUT (0x31)
                        Store (0x400, GHIN)               // Turn on invert to see falling edge
                        Store (One, Local0)
                    }
                } Else {                                  // Spurious event
                    If (And(GHIN, 0x400))
                    {                                     // Inverted, stayed open
                        Store (One, Local0)
//                        UPUT (0x61)
                    } Else {
                        Store (Zero, Local0)
//                        UPUT (0x62)
                    }
                }
//                UPUT (0x20)

                Return (Local0)
            }
        }

        Device (PCI0) {
            Name (_HID, EisaId ("PNP0A03"))
            Name (_ADR, Zero)

            // XXX Probably should be sleep state 0 - can't wake from PCI as power is off
//            Name (_PRW, Package (0x02) { 0x1f, 0x05 })
// XXX        Name (_PRW, Package (0x02) { 0x1f, 0x03 })

//            Name (_STA, 0x0F)
Method (_STA, 0, NotSerialized) { Return (0x0F) }

            /*
             I simplified this by omitting the LNKx devices, setting the source
             field to Zero, and putting the IRQ# in the source index field.
             See pdf p 208.  Programmable interrupt routing is useless on OLPC.
             */
            
            Name (_PRT, Package (0x15) {
                                 /* Address, pin#, source, source index */
//                Package (0x04) { 0x0001FFFF, Zero, Zero, 14 },  // Slot1 pin 0 - AES - IRQ 14
//                Package (0x04) { 0x000FFFFF,  One, Zero, 05 },  // SlotF pin 1 - Audio - IRQ 5
//                Package (0x04) { 0x000FFFFF, 0x03, Zero, 10 },  // SlotF pin 3 - UHCI and EHCI - IRQ 10
//                Package (0x04) { 0x000CFFFF, Zero, Zero, 11 },  // SlotC pin 1 - CaFe - IRQ 11

// XXX need an assignment of IRQ 14 to the AES device at dev 1, function 2 (INTA)
                  Package (0x04) { 0x0001FFFF, Zero, LNKC, Zero },  // Slot1 pin 0 - AES - IRQ 14
                  Package (0x04) { 0x0001FFFF, 0x02, LNKC, Zero },  // Slot1 pin 0 - AES - IRQ 14
                  Package (0x04) { 0x000FFFFF,  One, LNKB, Zero },  // SlotF pin 1 - Audio - IRQ 5
                  Package (0x04) { 0x000FFFFF, 0x03, LNKD, Zero },  // SlotF pin 3 - UHCI and EHCI - IRQ 10
                  Package (0x04) { 0x000CFFFF, Zero, LNKA, Zero },  // SlotC pin 1 - CaFe - IRQ 11
           })
            Name (CRES, ResourceTemplate () {
                WordBusNumber (ResourceConsumer, MinNotFixed, MaxNotFixed, PosDecode,
                    0x0000,             // Granularity
                    0x0000,             // Range Minimum
                    0x00FF,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0100,             // Length
                    ,, )
                IO (Decode16, 0x0CF8, 0x0CF8, 0x01, 0x08, )
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000, 0x0000, 0x0CF7, 0x0000, 0x0CF8,
                    ,, , TypeStatic)
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000, 0x0D00, 0xAC17, 0x0000, 0x9F18,
                    ,, , TypeStatic)
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000, 0xAC20, 0xFFFF, 0x0000, 0x53E0,
                    ,, , TypeStatic)

                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000, 0x000A0000, 0x000BFFFF, 0x00000000, 0x00020000,
                    ,, , AddressRangeMemory, TypeStatic)

//                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
//                    0x00000000, 0x000C0000, 0x000DFFFF, 0x00000000, 0x00020000,
//                    ,, , AddressRangeMemory, TypeStatic)

                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000, 0x000C8000, 0x000DFFFF, 0x00000000, 0x00018000,
                    ,, , AddressRangeMemory, TypeStatic)


// This is a template, edited by _CRS, for the address space that PCI claims between the top of main memory and
// the bottom of (SMM memory)?.
//                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
//                    0x00000000, 0x04000000, 0x403FFFFF, 0x00000000, 0x3C400000,
//                    ,, _Y04, AddressRangeMemory, TypeStatic)

// This is a template, edited by _CRS, for the address space that PCI claims abover the top of SMM memory
//                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
//                    0x00000000, 0x40500000, 0xEFFFFFFF, 0x00000000, 0xAFB00000,
//                    ,, _Y05, AddressRangeMemory, TypeStatic)

//                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
//                    0x00000000, 0xB0000000, 0xbfFFFFFF, 0x00000000, 0x10000000,
//                    ,, , AddressRangeMemory, TypeStatic)

// Since we can't plug in PCI devices, there is no need for an allocation pool of PCI address space
// We just declare a modest amount of PCI space and preassign device addresses in the firmware
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000, 0xfd000000, 0xfeFFFFFF, 0x00000000, 0x02000000,
                    ,, , AddressRangeMemory, TypeStatic)

//                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
//                    0x00000000, 0xF0000000, 0xFEFFFFFF, 0x00000000, 0x0f000000,
//                    ,, , AddressRangeMemory, TypeStatic)

            })
            Method (_CRS, 0, NotSerialized) {
//    VSAW(0, 2)
//                CreateDWordField (CRES, \_SB.PCI0._Y04._MIN, RMIN)
//                CreateDWordField (CRES, \_SB.PCI0._Y04._MAX, RMAX)
//                CreateDWordField (CRES, \_SB.PCI0._Y04._LEN, RLEN)
//                CreateDWordField (CRES, \_SB.PCI0._Y05._MIN, PMIN)
//                CreateDWordField (CRES, \_SB.PCI0._Y05._MAX, PMAX)
//                CreateDWordField (CRES, \_SB.PCI0._Y05._LEN, PLEN)
//                Store (ZZY6, Local0)             // size from EBDA[0x180]
//                Add (Local0, 0x40, Local0)       // + 64
//                ShiftLeft (Local0, 0x0A, RMIN)   // * 1024 -> RMIN above
//                Subtract (0x80400000, One, RMAX) // 803f.ffff -> RMAX above
//                Subtract (RMAX, RMIN, Local1)
//                Increment (Local1)
//                Store (Local1, RLEN)                   // -> RLEN above
//                Add (0x80400000, 0x00100000, PMIN)     // -> PMIN
//                Add (Subtract (PMAX, PMIN), One, PLEN) // -> PLEN
                Return (CRES)
            }

            Device (SBF0) {   /* Southbridge function 0 */
                Name (_ADR, 0x000F0000)                          // PCI dev F, fn 0
                Method (_INI, 0, NotSerialized) {
  ^^^_INI () 
//    VSAW(0, 3)
}  // Call root _INI ?  Parent: PCI0 Grandparent: system bus

                Device (RTC0) {
//   Method (_INI, 0, NotSerialized) { VSAW(1, 0x55) }

                    Name (_HID, EisaId ("PNP0B00"))
                    Name (_UID, Zero)
//                    Name (_STA, 0x0F)
Method (_STA, 0, NotSerialized) {
// VSAW(1, 0x56)
 Return (0x0F) }

                    Name (_CRS, ResourceTemplate () {
                        IRQNoFlags () {8}
                        IO (Decode16, 0x0070, 0x0070, 0x00, 0x04, )
                    })
                }

                Device (TMR) {
//   Method (_INI, 0, NotSerialized) { VSAW(2, 0x55) }
                    Name (_HID, EisaId ("PNP0100"))
//                    Name (_STA, 0x0F)
Method (_STA, 0, NotSerialized) {
// VSAW(2, 0x56)
 Return (0x0F) }
                    Name (_CRS, ResourceTemplate () {
                        IRQNoFlags () {0}
                        IO (Decode16, 0x0040, 0x0040, 0x00, 0x04, )
                        IO (Decode16, 0x0048, 0x0048, 0x00, 0x04, )
                    })
                }

// Elided speaker

// XXX ??? Do we need to reinstate this MEM node???

                Device (MEM) {
//   Method (_INI, 0, NotSerialized) { VSAW(3, 0x55) }
                    Name (_HID, EisaId ("PNP0C01"))
                    Name (_UID, One)
                    Method (_CRS, 0, NotSerialized) {
// VSAW(0, 4)
                        Name (MBRB, ResourceTemplate () {
                            Memory32Fixed (ReadWrite, 0x00000000, 0x000A0000, )
                            Memory32Fixed (ReadOnly,  0x000E0000, 0x00020000, )
                            Memory32Fixed (ReadWrite, 0x00100000, 0x00000000, _Y06)  // Edited below
                            // Assumes that the SMM memory is at 8040.0000, I think
               //           Memory32Fixed (ReadOnly, 0x80400000, 0x00040000, )
                            Memory32Fixed (ReadOnly, 0xFFF00000, 0x00100000, )  // GeodeROM has f0000000,10000000

                            IO (Decode16, 0x0092, 0x0092, 0x00, 0x01, )
                        })
                        CreateDWordField (MBRB, \_SB.PCI0.SBF0.MEM._CRS._Y06._LEN, EM1L)
                        Store (ZZY6, Local0)                // Memory size in Kbytes (from EBDA)
                        Subtract (Local0, 0x0400, Local0)   // Subtract 1024 (for below 1M mem)
                        ShiftLeft (Local0, 0x0A, Local0)    // Multiply by 1K to convert to bytes
                        Store (Local0, EM1L)                // Punch into the data structure
                        Return (MBRB)
                    }
                }

                Device (PIC)
                {
//   Method (_INI, 0, NotSerialized) { VSAW(4, 0x55) }
                    Name (_HID, EisaId ("PNP0000"))
//                    Name (_STA, 0x0F)
Method (_STA, 0, NotSerialized) {
// VSAW(4, 0x56)
 Return (0x0F) }
                    Name (_CRS, ResourceTemplate () {
                        IRQNoFlags () {2}
                        IO (Decode16, 0x0020, 0x0020, 0x00, 0x02, )
                        IO (Decode16, 0x00A0, 0x00A0, 0x00, 0x02, )
                        IO (Decode16, 0x04D0, 0x04D0, 0x10, 0x02, )
                    })
                }

                Device (MAD)
                {
//   Method (_INI, 0, NotSerialized) { VSAW(5, 0x55) }
                    Name (_HID, EisaId ("PNP0200"))
//                    Name (_STA, 0x0F)
Method (_STA, 0, NotSerialized) {
// VSAW(5, 0x56)
 Return (0x0F) }
                    Name (_CRS, ResourceTemplate () {
                        DMA (Compatibility, BusMaster, Transfer8, ) {4}
                        IO (Decode16, 0x0000, 0x0000, 0x10, 0x10, )
                        IO (Decode16, 0x0080, 0x0080, 0x10, 0x10, )
                        IO (Decode16, 0x00C0, 0x00C0, 0x10, 0x20, )
                        IO (Decode16, 0x0480, 0x0480, 0x10, 0x10, )
                    })
                }

                Device (COPR) {
//   Method (_INI, 0, NotSerialized) { VSAW(6, 0x55) }
                    Name (_HID, EisaId ("PNP0C04"))
                    Name (_CRS, ResourceTemplate () {
                        IO (Decode16, 0x00F0, 0x00F0, 0x10, 0x10, )
                        IRQNoFlags () {13}
                    })
                }

// Elided UART

// Elided superio

// XXX ??? Maybe this should be moved out a level so it's not under SB F0
                Device (KBC) {
//   Method (_INI, 0, NotSerialized) { VSAW(7, 0x55) }
                    Name (_HID, EisaId ("PNP0303"))
                    Name (_CID, 0x0B03D041)

                    // Return this one if can wake from keyboard - XXX maybe need to be 3 instead of One
                    Name (_PRW, Package (0x02) { Zero, One })

// XXX ??? do we need a _PSW method?
                Method (_PSW, 1, NotSerialized) { }

                    // XXX Can we control whether or not the keyboard can wake us up?
                    Name (_CRS, ResourceTemplate () {
                        IRQNoFlags () {1}
                        IO (Decode16, 0x0060, 0x0060, 0x00, 0x01, )
                        IO (Decode16, 0x0064, 0x0064, 0x00, 0x01, )
                    })
//                    Name (_STA, 0x0F)
Method (_STA, 0, NotSerialized) {
// VSAW(7, 0x56)
 Return (0x0F) }
                }

                Device (PS2M) {
//   Method (_INI, 0, NotSerialized) { VSAW(0xc, 0x55) }
//                    Name (_HID, EisaId ("PNP0F13"))     // Microsoft Intellipoint
                    Name (_HID, EisaId ("PNP0F03"))     // ALPS Pointing device
                    Name (_CID, 0x130FD041)
                    Name (_PRW, Package (0x02) { Zero, One })
// XXX ??? do we need a _PSW method?
                    Method (_PSW, 1, NotSerialized) { }
                    Name (_CRS, ResourceTemplate () { IRQNoFlags () {12} })
//                    Name (_STA, 0x0F )
Method (_STA, 0, NotSerialized) {
// VSAW(0xc, 0x56)
 Return (0x0F) }
                }
// Elided FDC0
// Elided SuperIO UART
// Elided LPT
// Elided IDE
            }

            Device (USB0) {
//   Method (_INI, 0, NotSerialized) { VSAW(8, 0x55) }
                Name (_ADR, 0x000F0004)
                Name (_STR, Unicode ("CS553x USB Controller 0"))
//                Name (_STA, 0x0F)
Method (_STA, 0, NotSerialized) {
// VSAW(8, 0x56)
 Return (0x0F) }

                Name (_PRW, Package (0x02) { 0x06, One })
            }

            Device (USB1) {
//   Method (_INI, 0, NotSerialized) { VSAW(9, 0x55) }
                Name (_ADR, 0x000F0005)
                Name (_STR, Unicode ("CS553x USB Controller 1"))
//                Name (_STA, 0x0F)
Method (_STA, 0, NotSerialized) {
// VSAW(9, 0x56)
 Return (0x0F) }
                Name (_PRW, Package (0x02) { 0x06, One })
            }

//            Device (USB2) {
//   Method (_INI, 0, NotSerialized) { VSAW(0xa, 0x55) }
//                Name (_ADR, 0x000F0006)
//                Name (_STR, Unicode ("CS5536 USB Controller 2 (UDC)"))
//                Name (_STA, 0x0F)
//            }

//            Device (USB3) {
//   Method (_INI, 0, NotSerialized) { VSAW(0xb, 0x55) }
//                Name (_ADR, 0x000F0007)
//                Name (_STR, Unicode ("CS5536 USB Controller 3 (OTG)"))
//                Name (_STA, 0x0F)
//            }
        }
    }
}
