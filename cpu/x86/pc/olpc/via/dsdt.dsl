// LICENSE_BEGIN
//   Copyright (c) 2009 One Laptop per Child, Association, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// LICENSE_END

DefinitionBlock ("dsdt.aml",      // AML file name
                 "DSDT",          // Table signature, DSDT
                 0x01,            // Compliance Revision
                 "OLPC",          // OEM ID
                 "XO-1.5  ",      // Table ID
                 0x00000001)      // OEM Revision
{

OperationRegion (UART, SystemIO, 0x03f8, 0x07)

// set to 1 to enable debug output
Name (UDBG, 0)

// set to 1 to enable LID wakeups on both open/close
Name (LIDX, 0)

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
    If (UDBG) {
        While( LEqual (And (USTA, 0x20), Zero) ) {
            Stall (99)
        }
        Store (Arg0, UDAT)
    }
}

Method (UDOT, 1, NotSerialized)
{
    If (UDBG) {
        And (ShiftRight (Arg0, 4), 0xF, Local0)
        If (LLess (Local0, 10)) {
            Add (Local0, 0x30, Local0)  // '0'
        } Else {
            Add (Local0, 0x57, Local0)  // 'a' - 10
        }
        UPUT (Local0)

        And (Arg0, 0xF, Local0)
        If (LLess (Local0, 10)) {
            Add (Local0, 0x30, Local0)  // '0'
        } Else {
            Add (Local0, 0x57, Local0)  // 'a' - 10
        }
        UPUT (Local0)

        UPUT (0x20)
    }
}

OperationRegion(CMS1, SystemIO, 0x74, 0x2)
Field(CMS1, ByteAcc, NoLock, Preserve) {
    CMSI, 8,
    CMSD, 8
}

Method (CMSW, 2)
{
    Store (Arg0, CMSI)
    Store (Arg1, CMSD)
}

//  Processor Objects
Scope(\_PR)
{
    Processor(\_PR.CPU0,0x00,0x00000410,0x06)
    {
       Name(_CST, Package()
       {
           3,
           Package(){ResourceTemplate(){Register(SystemIO, 8, 0, 0x414)}, 2,   2, 750},
           Package(){ResourceTemplate(){Register(SystemIO, 8, 0, 0x415)}, 3,  65, 500},
           Package(){ResourceTemplate(){Register(SystemIO, 8, 0, 0x416)}, 3, 100, 300},
       })
    }
}

// System Sleep States
Name(\_S0,Package(){0,0,0,0})
Name(\_S1,Package(){4,4,4,4})
Name(\_S3,Package(){1,1,1,1})
Name(\_S4,Package(){2,2,2,2})
Name(\_S5,Package(){2,2,2,2})

OperationRegion(\DEBG, SystemIO, 0x80, 0x1)
Field(\DEBG, ByteAcc, NoLock, Preserve) {
    DBG1, 8,
}

// PMIO_RX04
OperationRegion(\SCIE, SystemIO, 0x0404, 0x2)   // Genernal Purpose SCI Enable
Field(\SCIE, ByteAcc, NoLock, Preserve) {
    SCIZ,   1,                                  // SCI / SMI enable
}

OperationRegion(\GPST, SystemIO, 0x0420, 0x2)
Field(\GPST, ByteAcc, NoLock, Preserve) {
    GS00,1,     // GPI0
    GS01,1,     // GPI1 (GPWAKE)
    GS02,1,     // internal KBC PME
    GS03,1,     // V1 Interrupt
    GS04,1,     // EXTSMI#
    GS05,1,     // PME#
    GS06,1,     // INTRUDER#
    GS07,1,     // GP3 timer timeout
    GS08,1,     // ring
    GS09,1,     // mouse controller PME
    GS10,1,     // thermal detect (ebook)
    GS11,1,     // LID#
    GS12,1,     // battery low
    GS13,1,     // HDAC wakeup
    GS14,1,     // USB wakeup
    GS15,1,     // north module SERR#
}

OperationRegion(GPIO, SystemIO, 0x0448, 0x4)
Field(GPIO, ByteAcc, NoLock, Preserve) {
        ,7,
    GPI7,1,     // lid
        ,1,
    GPI9,1,     // ebook
        ,22,
}

// PMIO_RX22/3
OperationRegion(\GPSE, SystemIO, 0x0422, 0x2)   // Genernal Purpose SCI Enable
Field(\GPSE, ByteAcc, NoLock, Preserve) {
    GPS0,   1,                                  // GPI0 SCI Enable
    GPWK,   1,                                  // GPI1 SCI Enable
    KBCE,   1,                                  // PS2 KB PME Enable
        ,   1,
    EXTE,   1,                                  // EXTSMI# Enable
    PME,    1,                                  // PCI PME Enable
        ,   2,
    RING,   1,                                  // Ring Wakeup
        ,   1,
    THRM,   1,                                  // Ebook/Thermal detect
    LID,    1,                                  // Lid Wakeup
        ,   1,                                  // BATLOW Enable
    HDA,    1,                                  // HDA Enable
    USBE,   1,                                  // USB Resume
        ,   1,                                  // NB SERR Detect
}

// PMIO_RX28/9
OperationRegion(\Glos, SystemIO, 0x0428, 0x2)   // Global Status
Field(\Glos, ByteAcc, NoLock, Preserve) {
        , 6,                                    //
    SSMI, 1,                                    // software SMI
    PRII, 1,                                    // primary IRQ
        , 2,                                    //
    SLPE, 1,                                    // sleep enable(Rx05)
    SIRS, 1,                                    // serirq status
        , 4,
}

OperationRegion(\WIRQ, SystemIO, 0x042a, 0x1)   // IRQ Resume Reg
Field(\WIRQ, ByteAcc, NoLock, Preserve) {
    IRQR, 8,
}

// from BIOS porting guide, section 13.2.2
OperationRegion(\EDGE, SystemIO, 0x042c, 1)   // SMI enable, lid edge polarity
Field(\EDGE, ByteAcc, NoLock, Preserve) {
        , 1,                                    // SMI enable (1 == enable)
        , 1,                                    //
    PPOL, 1,                                    // power button polarity (1 == falling)
        , 1,                                    //
        , 1,                                    //
        , 1,                                    // battery low enable (0 == enable)
    TPOL, 1,                                    // therm polarity (1 == falling)
    LPOL, 1,                                    // lid polarity (1 == falling)
}

OperationRegion(\Stus, SystemIO, 0x0430, 0x1)   // Global Status
Field(\Stus, ByteAcc, NoLock, Preserve) {
    PADS, 8,
}

OperationRegion(\Prie, SystemIO, 0x0434, 0x1)
Field(\Prie, ByteAcc, NoLock, Preserve) {
        , 5,
    CMAE, 1,    // COMA_EN
    CMBE, 1,    // COMB_EN
}

//
//  General Purpose Event
//
Scope(\_GPE)
{
    Method(_L01) {
        UPUT (0x31)         // 1
        Notify(\_SB.PCI0.EC, 0x80)    // GPWAKE, from the EC
    }

    Method(_L02) {
        UPUT (0x33)         // 3
        Notify(\_SB.PCI0.VT86.PS2K, 0x02)       //Internal Keyboard PME Status
    }

    Method(_L04) {
        UPUT (0x34)         // 4
        Notify(\_SB.SLPB, 0x80)
    }

    Method(_L05) {
        UPUT (0x35)         // 5
        Notify(\_SB.PCI0,0x2)
    }

    Method(_L09) {
        UPUT (0x39)         // 9
        Notify(\_SB.PCI0.VT86.PS2M, 0x02)       //Internal Mouse Controller PME Status
    }

    Method(_L0A) {          // EBOOK event (THRM#)
        UPUT (0x65)         // e
        Not(TPOL, TPOL)     // Flip the therm polarity bit
        Store (One, GS10)   // clear interrupt caused by polarity flip
        Notify(\_SB.PCI0.EBK, 0x80)
    }

    Method(_L0B) {          // LID event
        UPUT (0x66)         // f
        Store (GPI7, LPOL)  // set edge detect from current lid state
        Notify(\_SB.PCI0.LID, 0x80)
    }

    Method(_L0D) {
        Notify(\_SB.PCI0.HDAC, 0x02)
    }

    Method(_L0E) {                              //USB Wake up Status
        Notify(\_SB.PCI0.USB1, 0x02)
        Notify(\_SB.PCI0.USB2, 0x02)
        Notify(\_SB.PCI0.USB3, 0x02)
        Notify(\_SB.PCI0.EHCI, 0x02)
    }
}

Name(PICF,0x00) // PIC or APIC?
Method(_PIC, 0x01, NotSerialized) {
    Store (Arg0, PICF)
}

//
// System Wake up
//
Method(_WAK, 1, Serialized)
{
    Notify(\_SB.PCI0.USB1, 0x00)
    Notify(\_SB.PCI0.USB2, 0x00)
    Notify(\_SB.PCI0.USB3, 0x00)
    Notify(\_SB.PCI0.EHCI, 0x00)

    Store(One, SCIZ)

    If (LEqual (Arg0, 1))       //S1
    {
        Notify (\_SB.SLPB, 0x02)
    }

    Or (Arg0, 0xA0,  Local0)
    Store (Local0, DBG1)    //80 Port: A1, A2, A3....

    IF (LEqual(Arg0, 0x01))   //S1
    {
        And(IRQR,0x7F,IRQR)     //Disable IRQ Resume Reg, IRQR:Rx2A
        While(PRII){            //PRII:Rx28[7]
            Store (One, PRII)   //Clear Primary IRQ resume Status
        }
        While(LNotEqual(PADS, 0x00))    //PADS: Rx30[1:7]
        {
            Store (PADS, PADS)  //Clear Primary Activity Detect Status
        }
    }

    Notify(\_SB.SLPB, 0x2)

    IF (LEqual(Arg0, 0x03))     //S3
    {
        Store(0x2,\_SB.PCI0.MEMC.FSEG)  //Set F Segment to Read only
    }

    Or (Arg0, 0xB0,  Local0)
    Store (Local0, DBG1)    //80 Port: B1, B2, B3....

    // always want to hear both lid events when awake
    Store (GPI7, LPOL)  // watch either edge

    Return (0)
}

//
// System sleep down
//
Method (_PTS, 1, NotSerialized)
{
    Or (Arg0, 0xF0,  Local0)
    Store (Local0, DBG1)    //80 Port: F1, F2, F3....

    // if (LIDX == 0), wake on rising edge only, else watch either
    Store (And(LIDX, GPI7), LPOL)

    IF (LEqual(Arg0, 0x01))       // S1
    {
        While(PRII)
        {
            Store (One, PRII)   // Clear Primary IRQ resume Status
        }
        While(LNotEqual(PADS, 0x00))
        {
            Store (PADS, PADS)  // Clear Primary Activity Detect Status
        }
        Or(IRQR,0x80,IRQR)      // Enable IRQ Resume Reg

    } //End of Arg0 EQ 0x01

    IF (LEqual(Arg0, 0x03)) {       // S3
        Store(0x0,\_SB.PCI0.MEMC.FSEG)     // Disable F Segment Read/Write
    }

    IF (LEqual(Arg0, 0x04)) {       //S4
    }

    IF (LEqual(Arg0, 0x05)) {       //S5
        Store (Zero, GS04)          // Clear EXTSMI# Status, why?
     }
    Sleep(0x64)
    Return (0x00)
}

//  Method(STRC, 2) {   // Compare two String
//      If(LNotEqual(Sizeof(Arg0), Sizeof(Arg1))) {
//          Return(1)
//      }
//
//      Add(Sizeof(Arg0), 1, Local0)
//
//      Name(BUF0, Buffer(Local0) {})
//      Name(BUF1, Buffer(Local0) {})
//
//      Store(Arg0, BUF0)
//      Store(Arg1, BUF1)
//
//      While(Local0) {
//          Decrement(Local0)
//          If(LNotEqual(Derefof(Index(BUF0, Local0)), Derefof(Index(BUF1, Local0)))) {
//              Return(1)
//          }
//      }
//      Return(0)           // Str1 & Str2 are match
//  }

//
//  System Bus
//
Scope(\_SB)
{

    Method(_INI, 0)
    {
        Store(One, SCIZ)
    }

    Device (SLPB)
    {
        Name (_HID, EISAID("PNP0C0E"))  // Hardware Device ID SLEEPBTN
        Name (_STA, 0)                  // not present on XO.  note that there are still
                                        // Notify() calls to SLPB -- not sure what that will do.
        Name(_PRW, Package(2){0x04,5})  //Internal Keyboard Controller PME Status; S5
    }

    Device(PCI0)
    {
// Our WindowsXP SD build doesn't handle PCIe, so we have to claim basic PCI
//      Name(_HID,EISAID ("PNP0A08"))    // Indicates PCI Express host bridge hierarchy
//      Name(_CID,EISAID ("PNP0A03"))    // For legacy OS that doesn't understand the new HID
        Name(_HID,EISAID ("PNP0A03"))    // For legacy OS that doesn't understand the new HID

        Name(_ADR,0x00000000)            // Device (HI WORD)=0, Func (LO WORD)=0

        Name (_BBN,0)

        Method(_INI, 0)
        {
            UPUT (0x4a)  // J
        }

        Name (_S3D, 3)

        Method(_STA, 0) {
            Return(0x0F)        // present, enabled, functioning
        }

        Name(_PRW, Package(2){0x5,0x4})     // PME#

        Method(_CRS,0) {
            Name(BUF0,ResourceTemplate() {
                WORDBusNumber(          // Bus 0
                    ResourceConsumer,
                    MinNotFixed,
                    MaxNotFixed,
                    PosDecode,
                    0x0000,
                    0x0000,
                    0x00FF,
                    0x0000,
                    0x0100
                )

                IO(             // IO Resource for PCI Bus
                    Decode16,
                    0x0CF8,
                    0x0CF8,
                    1,
                    8
                )

                WORDIO(         // IO from 0x0000 - 0x0cf7
                    ResourceProducer,
                    MinFixed,
                    MaxFixed,
                    PosDecode,
                    EntireRange,
                    0x0000,
                    0x0000,
                    0x0CF7,
                    0x0000,
                    0x0CF8
                )

                WORDIO(         // IO from 0x0d00 - 0xffff
                    ResourceProducer,
                    MinFixed,
                    MaxFixed,
                    PosDecode,
                    EntireRange,
                    0x0000,
                    0x0D00,
                    0xFFFF,
                    0x0000,
                    0xF300
                )

                DWORDMemory(
                    ResourceProducer,
                    PosDecode,
                    MinFixed,
                    MaxFixed,
                    Cacheable,
                    ReadWrite,
                    0x00000000,
                    0x000A0000,
                    0x000BFFFF,
                    0x00000000,
                    0x00020000
                )

                DWORDMemory(
                    ResourceProducer,
                    PosDecode,
                    MinFixed,
                    MaxFixed,
                    Cacheable,
                    ReadWrite,
                    0x00000000,
                    0x000C0000,
                    0x000DFFFF,
                    0x00000000,
                    0x00020000
                )
    // XXX I don't know what this is
               DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                        0x00000000,
                        0xFED40000,
                        0xFED44FFF,
                        0x00000000,
                        0x00005000,
                        )
                DWORDMemory(                // Consumed-and-produced resource(all of memory space)
                    ResourceProducer,       // bit 0 of general flags is 0
                    PosDecode,              // positive Decode
                    MinFixed,               // Range is fixed
                    MaxFixed,               // Range is fixed
                    Cacheable,
                    ReadWrite,
                    0x00000000,             // Granularity
                    0x80000000,             // Min (calculated dynamically)
                    0xBfffffff,             //  Max = 4GB - 1MB  (fwh + fwh alias...)
                    0x00000000,             // Translation
                    0x40000000,             // Range Length (calculated dynamically)
                    ,                       // Optional field left blank
                    ,                       // Optional field left blank
                    MEM3                    // Name declaration for this descriptor
                    )
            }) // end of BUF0

            CreateDWordField(BUF0,MEM3._MIN, PMRN)
            CreateDWordField(BUF0,MEM3._MAX, PMRM)
            CreateDWordField(BUF0,MEM3._LEN, PMRL)
            // XXX top of PCI memory space
            Store(0xFFE80000, PMRM)
            Store(\_SB.PCI0.MEMC.LTMA, Local0)
            ShiftLeft(Local0, 16, PMRN)
            Subtract (PMRM, PMRN, PMRL)

            Return(BUF0)
        } // end of CRS

        Device(MEMC) {
            Name(_ADR, 0x00000003)

            Method(_STA, 0) {
                    Return(0x0F)        // present, enabled, functioning
            }

            OperationRegion(MCPS,PCI_Config,0x00,0x100)
            Field(MCPS,ByteAcc,NoLock,Preserve)
            {
                Offset(0x83),
                    , 4,
                FSEG, 2,            //Rx83[4:5]
                    , 2,

                Offset(0x84),
                LTMA, 16,           //Rx84 and Rx85. Low Top Address of Memory

                Offset(0x86),
                    , 2,
                ENTS, 1,            //Enable Top SMRAM Size
                    , 3,
                TSMS, 2,            // Top SMRAM Size

                Offset(0xA1),
                    , 4,
                FBSZ, 3,            // Frame Buffer Size
                ENIG, 1,            // Enable Internal Graphic
            }
        }

        // USBD Controller
        Device (USBD)
        {
            Name(_ADR, 0x000B0000)

            OperationRegion(RUDC,PCI_Config,0x00,0x100)
            Field(RUDC,ByteAcc,NoLock,Preserve){
                Offset(0x00),
                VID, 16,
                Offset(0x04),
                CMDR, 3,
            }

            Method(_STA, 0)
            {
                If(LNotEqual(\_SB.PCI0.USBD.VID, 0x1106)) {
                    Return(0x00)
                } Else {
                    If(LEqual(\_SB.PCI0.USBD.CMDR, 0x00)) {
                        Return(0x0D)
                    } Else {
                        Return(0x0F)    // present, enabled, functioning
                    }
                }
            }
        }//Device(USBD)

        // SDIO Controller
        Device (SDIO)
        {
            Name(_ADR, 0x000C0000)

            OperationRegion(RSDC,PCI_Config,0x00,0x100)
            Field(RSDC,ByteAcc,NoLock,Preserve){
                Offset(0x00),
                VID, 16,
                Offset(0x04),
                CMDR, 3,
            }

            Method(_STA, 0)
            {
                If(LNotEqual(\_SB.PCI0.SDIO.VID, 0x1106)) {
                    Return(0x00)
                } Else {
                    If(LEqual(\_SB.PCI0.SDIO.CMDR, 0x00)) {
                        Return(0x0D)
                    } Else {
                        Return(0x0F)    // present, enabled, functioning
                    }
                }
            }
        }//Device(SDIO)

        // SD $ MS Controller
        Device (SDMS)
        {
            Name(_ADR, 0x000D0000)

            OperationRegion(RSDM,PCI_Config,0x00,0x100)
            Field(RSDM,ByteAcc,NoLock,Preserve){
                Offset(0x00),
                VID, 16,
                Offset(0x04),
                CMDR, 3,
            }

            Method(_STA, 0)
            {
                If(LNotEqual(\_SB.PCI0.SDMS.VID, 0x1106)) {
                    Return(0x00)
                } Else {
                    If(LEqual(\_SB.PCI0.SDMS.CMDR, 0x00)) {
                        Return(0x0D)
                    } Else {
                        Return(0x0F)    // present, enabled, functioning
                    }
                }
            }
        }//Device(SDMS)

        // CE-ATA $ NF Controller(Card Boot)
        Device(CENF)
        {
            Name(_ADR, 0x000E0000)

            OperationRegion(RENF,PCI_Config,0x00,0x100)
            Field(RENF,ByteAcc,NoLock,Preserve){
                Offset(0x00),
                VID, 16,
                Offset(0x04),
                CMDR, 3,
            }

            Method(_STA, 0)
            {
                If(LNotEqual(\_SB.PCI0.CENF.VID, 0x1106)) {
                    Return(0x00)
                } Else {
                    If(LEqual(\_SB.PCI0.CENF.CMDR, 0x00)) {
                        Return(0x0D)
                    } Else {
                        Return(0x0F)    // present, enabled, functioning
                    }
                }
            }
        }

        Device(IDEC)
        {

            Name(_ADR, 0x000F0000)  //D15F0: a Pata device

            Method(_STA,0,NotSerialized)    //Status of the Pata Device
            {
                If(LNot(LEqual(\_SB.PCI0.IDEC.VID,0x1106)))
                {
                    Return(0x00)    //device not exists
                }
                Else
                {
                    If(LEqual(\_SB.PCI0.IDEC.CMDR,0x00))
                    {
                        Return(0x0D)        //device exists & disable
                    }
                    Else
                    {
                        Return(0x0F)        //device exists & enable
                    }
                }
            }
            OperationRegion(SAPR,PCI_Config,0x00,0xC2)
            Field(SAPR,ByteAcc,NoLock,Preserve)
            {
                VID,16,
                Offset(0x04),
                CMDR,3,
                Offset(0x40),
                        , 1,
                EPCH, 1,                    // Enable Primary channel.
                Offset(0x4A),
                PSPT, 8,                    // IDE Timings, Primary Slave
                PMPT, 8,                    // IDE Timings, Primary Master
                Offset(0x52),
                PSUT, 4,                    // Primary Slave UDMA Timing
                PSCT, 1,                    // Primary Drive Slave Cabal Type
                PSUE, 3,                    // Primary Slave UDMA Enable
                PMUT, 4,                    // Primary Master UDMA Timing
                PMCT, 1,                    // Primary Drive Master Cabal Type
                PMUE, 3,                    // Primary Master UDMA Enable
            }

            Name(REGF,0x01)         //accessible OpRegion default
            Method(_REG,2,NotSerialized)    // is PCI Config space accessible as OpRegion?
            {
                If(LEqual(Arg0,0x02))
                {
                    Store(Arg1,REGF)
                }
            }
            /*
            Name(TIM0,Package(0x04){
                Package(){0x78,0xB4,0xF0,0x017F,0x0258},
                Package(){0x20,0x22,0x33,0x47,0x5D},
                Package(){0x78,0x50,0x3C,0x2D,0x1E,0x14,0x0F},
                Package(){0x06,0x05,0x04,0x04,0x03,0x03,0x02,0x02,0x01,0x01,0x01,0x01,0x01,0x01,0x00}
            })
        */
            Name(TIM0, Package()
            {                               // Primary / Secondary channels timings
                Package(){120, 180, 240, 383, 600},         // Timings in ns - Mode 4,3,2,1,0 defined from ATA spec.
                Package(){0x20, 0x22, 0x33, 0x47, 0x5D },   // PIO Timing - Mode 4,3,2,1,0
                Package(){4, 3, 2, 1, 0},                           // PIO mode (TIM0,0)
                Package(){2, 1, 0, 0},                              // Multi-word DMA mode
                Package(){120, 80, 60, 45, 30, 20, 15},         // Min UDMA Timings in ns
                Package(){6,5,4,4,3,3,2,2,1,1,1,1,1,1,0},   // UDMA mode
                Package(){0x0E, 8, 6, 4, 2, 1, 0},          // UDMA timing
            })

            Name(TMD0,Buffer(0x14){})
            CreateDwordField(TMD0,0x00,PIO0)
            CreateDwordField(TMD0,0x04,DMA0)
            CreateDwordField(TMD0,0x08,PIO1)
            CreateDwordField(TMD0,0x0C,DMA1)
            CreateDwordField(TMD0,0x10,CHNF)

            Name(GMPT, 0)           // Master PIO Timings
            Name(GMUE, 0)           // Master UDMA enable
            Name(GMUT, 0)           // Master UDMA Timings
            Name(GSPT, 0)           // Slave PIO Timings
            Name(GSUE, 0)           // Slave UDMA enable
            Name(GSUT, 0)           // Slave UDMA Timings

            Device(CHN0)    //Primary Channel: Pata device
            {
                Name(_ADR,0x00)

                Method(_STA,0,NotSerialized)
                {
                    If(LNotEqual(\_SB.PCI0.IDEC.EPCH, 0x1))
                    {
                        Return(0x00)        //channel disable
                    }
                    Else
                    {
                        Return(0x0F)        //channel enable
                    }
               }
                Method(_GTM,0,NotSerialized)        //Get Timing Mode
                {
                    Return(GTM(PMPT,PMUE,PMUT,PSPT,PSUE,PSUT))
                }
                Method(_STM, 3)                     // Set Timing PIO/DMA Mode
                {
                   Store(Arg0, TMD0)        // Copy Arg0 into TMD0 buffer
                   Store(PMPT, GMPT)        // Master PIO Timings
                   Store(PMUE, GMUE)        // Master UDMA enable
                   Store(PMUT, GMUT)        // Master UDMA Timings
                   Store(PSPT, GSPT)        // Slave PIO Timings
                   Store(PSUE, GSUE)        // Slave UDMA enable
                   Store(PSUT, GSUT)        // Slave UDMA Timings
                   STM()
                   Store(GMPT, PMPT)        // Master PIO Timings
                   Store(GMUE, PMUE)        // Master UDMA enable
                   Store(GMUT, PMUT)        // Master UDMA Timings
                   Store(GSPT, PSPT)        // Slave PIO Timings
                   Store(GSUE, PSUE)        // Slave UDMA enable
                   Store(GSUT, PSUT)        // Slave UDMA Timings
                }                           // end Method _STM

                Device(DRV0)        //Master Device
                {
                    Name(_ADR,0x00) //0 indicates master drive
                    Method(_GTF,0,NotSerialized)    //Get Task File: return a buffer of ATA command used to re-initialize the device
                    {
                            Return(GTF(0,PMUE,PMUT,PMPT))
                    }
                }
                Device(DRV1)        //Slave Device
                {
                    Name(_ADR,0x01) //1 indicates slave drive
                    Method(_GTF,0,NotSerialized)    //Get Task File: return a buffer of ATA command used to re-initialize the device
                    {
                            Return(GTF(0,PSUE,PSUT,PSPT))
                    }
                }
            }

            Method(GTM,6,Serialized)
            {
                Store(Ones,PIO0)    //default value: all bits set to 1
                Store(Ones,PIO1)    //default value: all bits set to 1
                Store(Ones,DMA0)    //default value: all bits set to 1
                Store(Ones,DMA1)    //default value: all bits set to 1
                Store(0x10,CHNF)    //default value: 0x10
                If(REGF)
                {
                }
                Else
                {
                    Return(TMD0)    //unable to setup PCI config space as opRegion;return default value
                }
                Store(Match(DeRefOf(Index(TIM0,0x01)),MEQ,Arg0,MTR,0x00,0x00),Local6)
                If(LLess(Local6,Ones))
                {
                    Store(DeRefOf(Index(DeRefOf(Index(TIM0,0x00)),Local6)),Local7)
                    Store(Local7,DMA0)
                    Store(Local7,PIO0)
                }
                Store(Match(DeRefOf(Index(TIM0,0x01)),MEQ,Arg3,MTR,0x00,0x00),Local6)
                If(LLess(Local6,Ones))
                {
                    Store(DeRefOf(Index(DeRefOf(Index(TIM0,0x00)),Local6)),Local7)
                    Store(Local7,DMA1)
                    Store(Local7,PIO1)
                }
                If(Arg1)
                {
                    Store(DeRefOf(Index(DeRefOf(Index(TIM0,0x05)),Arg2)),Local5)
                    Store(DeRefOf(Index(DeRefOf(Index(TIM0,0x04)),Local5)),DMA0)
                    Or(CHNF,0x01,CHNF)
                }
                If(Arg4)
                {
                    Store(DeRefOf(Index(DeRefOf(Index(TIM0,0x05)),Arg5)),Local5)
                    Store(DeRefOf(Index(DeRefOf(Index(TIM0,0x04)),Local5)),DMA1)
                    Or(CHNF,0x04,CHNF)
                }
                Return(TMD0)        //return timing mode
            }

            Method(STM, 0, Serialized)
            {

                If(REGF){}                  // PCI space not accessible
                Else        {  Return(TMD0)  }

                Store(0x00, GMUE)           // Master UDMA Disable
                Store(0x00, GSUE)           // Slave UDMA Disable
                Store(0x07, GMUT)           // Master UDMA Mode 0
                Store(0x07, GSUT)           // Slave UDMA Mode 0

                If(And(CHNF, 0x1))
                {
                    Store(Match(DeRefOf(Index(TIM0, 4)), MLE, DMA0, MTR,0,0), Local0)    // Get DMA mode
                    Store(DeRefOf(Index(DeReFof(Index(TIM0, 6)), Local0)), GMUT)         // Timing bit mask 66Mhz
                    Or(GMUE, 0x07, GMUE)                                    // Enable UltraDMA for Device 0
                }
                Else        // non - UDMA mode. Possible Multi word DMA
                {
                    If(Or(LEqual(PIO0,Ones), LEqual(PIO0,0)))
                    {
                        If(And(LLess(DMA0,Ones), LGreater(DMA0,0)))
                        {
                            Store(DMA0, PIO0)       // Make PIO0=DMA0
                        }
                    }
                }

                If(And(CHNF, 0x4))
                {
                    Store(Match(DeRefOf(Index(TIM0, 4)), MLE, DMA1, MTR,0,0), Local0)
                    Store(DeRefOf(Index(DeReFof(Index(TIM0, 6)), Local0)), GSUT) // Timing bit mask 66Mhz
                    Or(GSUE, 0x07, GSUE)    // Enable UltraDMA for Device 0
                }
                Else        // non - UDMA mode. Possible Multi word DMA
                {
                    If(Or(LEqual(PIO1, Ones), LEqual(PIO1,0)))
                    {
                        If(And(LLess(DMA1, Ones), LGreater(DMA1,0)))
                        {
                           Store(DMA1, PIO1)        // Make PIO1 = DMA1
                        }
                    }
                }

                And(Match(DeRefOf(Index(TIM0, 0)), MGE, PIO0, MTR,0,0), 0x3, Local0)
                Store(DeRefOf(Index(DeReFof(Index(TIM0, 1)), Local0)), Local1)
                Store(Local1, GMPT)

                And(Match(DeRefOf(Index(TIM0, 0)), MGE, PIO1, MTR,0,0), 0x3, Local0)
                Store(DeRefOf(Index(DeReFof(Index(TIM0, 1)), Local0)), Local1)
                Store(Local1, GSPT)
                Return(TMD0)
            } // end Method STM

            Method(GTF , 4 , Serialized)
            {
                Store(Buffer(7){0x03, 0x00, 0x00, 0x00, 0x00, 0xA0, 0xEF}, Local1)
                Store(Buffer(7){0x03, 0x00, 0x00, 0x00, 0x00, 0xA0, 0xEF}, Local2)
                CreateByteField(Local1, 1, Mode)            // PIO mode
                CreateByteField(Local2, 1, UMOD)            // Ultra mode
                CreateByteField(Local1, 5, PCHA)            // master or slave
                CreateByteField(Local2, 5, UCHA)            // master or slave
                And(Arg0,0x03,Local3)

                If(Lequal(And(Local3,0x01),0x01))
                {
                    Store(0xB0,PCHA)        // drive 1
                    Store(0xB0,UCHA)        // drive 1
                }

                If(Arg1)
                {
                    Store(DeRefOf(Index(DeReFof(Index(TIM0, 5)), Arg2)), UMOD)     //Programming DMA Mode
                    Or( UMOD, 0x40, UMOD)
                }
                Else
                {   // non-UltraDMA
                    Store(Match(DeRefOf(Index(TIM0, 1)), MEQ, Arg3, MTR,0,0), Local0)
                    Or(0x20, DeRefOf(Index(DeReFof(Index(TIM0, 3)), Local0)), UMOD)
                }

                Store(Match(DeRefOf(Index(TIM0, 1)), MEQ, Arg3, MTR,0,0), Local0)
                Or(0x08, DeRefOf(Index(DeReFof(Index(TIM0, 2)), Local0)), Mode)
                Concatenate(Local1, Local2, Local6)
                Return(Local6)

            } // end of GTF
        }

        Device(USB1)        {
            Name(_ADR,0x00100000)   //Address+function.

            Name(_PRW, Package(2){0x0E,3})

            Name(_S3D, 3)

            OperationRegion(U2F0,PCI_Config,0x00,0xC2)
            Field(U2F0,ByteAcc,NoLock,Preserve){
                    Offset(0x00),
                    VID, 16,
                    Offset(0x04),
                    CMDR, 3,
                    Offset(0x3c),
                    U3IR, 4,                        //USB1 Interrupt Line
                    Offset(0x84),
                    ECDX, 2                         //USB1 PM capability status register
            }

            Method(_STA,0) {                        //Status of the USB1 Device
                If(LEqual(\_SB.PCI0.USB1.CMDR, 0x00)) {
                    Return(0x0D)
                } Else {
                    Return(0x0F)
                }
            }
        }

        Device(USB2)        {
            Name(_ADR,0x00100001)   //Address+function.

            Name(_PRW, Package(2){0x0E,3})

            Name(_S3D, 3)

            OperationRegion(U2F1,PCI_Config,0x00,0xC2)
            Field(U2F1,ByteAcc,NoLock,Preserve){
                    Offset(0x00),
                    VID, 16,
                    Offset(0x04),
                    CMDR, 3,
                    Offset(0x3c),
                    U4IR, 4,                        //USB2 Interrupt Line
                    Offset(0x84),
                    ECDX, 2                         //USB2 PM capability status register
            }

            Method(_STA,0) {                        //Status of the USB2 Device
                If(LEqual(\_SB.PCI0.USB2.CMDR, 0x00)) {
                    Return(0x0D)
                } Else {
                    Return(0x0F)
                }
            }
        }

        Device(USB3) {
            Name(_ADR,0x00100002)   //Address+function.

            Name(_PRW, Package(2){0x0E,3})

            Name(_S3D, 3)

            OperationRegion(U2F2,PCI_Config,0x00,0xC2)
            Field(U2F2,ByteAcc,NoLock,Preserve){
                Offset(0x00),
                VID, 16,
                Offset(0x04),
                CMDR, 3,
                Offset(0x3c),
                U5IR, 4,                    //USB3 Interrupt Line
                Offset(0x84),
                ECDX, 2                             //USB3 PM capability status register
            }

            Method(_STA,0) {                        //Status of the USB3 Device
                If(LEqual(\_SB.PCI0.USB3.CMDR, 0x00)) {
                    Return(0x0D)
                } Else {
                    Return(0x0F)
                }
            }
        }

        Device(EHCI)  {
            Name(_ADR,0x00100004)   //Address+function.

            Name(_PRW, Package(2){0x0E,3})

            Name(_S3D, 3)

            OperationRegion(U2F4,PCI_Config,0x00,0xC2)
            Field(U2F4,ByteAcc,NoLock,Preserve){
                Offset(0x00),
                VID, 16,
                Offset(0x04),
                CMDR, 3,
                Offset(0x3c),
                U7IR, 4,                    //EHCI1 Interrupt Line
                Offset(0x84),
                ECDX, 2                             //EHCI1 PM capability status register
            }

            Method(_STA,0) {                        //Status of the EHCI1 Device
                If(LEqual(\_SB.PCI0.EHCI.CMDR, 0x00)) {
                    Return(0x0D)
                } Else {
                    Return(0x0F)
                }
            }
        }

        Device (PEXX)
        {
            Name (_HID, EISAID ("PNP0C01"))
            Name (_STA, 0x0F)
            Name (_CRS,
                ResourceTemplate()
                {
                    Memory32Fixed (ReadWrite, 0xE0000000, 0x10000000)
                }
            )
        }

        Device(VT86)
        {
            Name(_ADR,0x00110000)   //Address+function.

            OperationRegion(VTSB, PCI_Config, 0x00, 0x100)
            Field(\_SB.PCI0.VT86.VTSB,ByteAcc,NoLock,Preserve) {
                Offset(0x2),
                DEID, 16,   // Device ID

                Offset(0x2C),
                ID2C,8,             // RX2C
                ID2D,8,             // RX2D
                ID2E,8,             // RX2E
                ID2F,8,             // RX2F

                Offset(0x44),
                PIRE, 4,
                PIRF, 4,
                PIRG, 4,
                PIRH, 4,    // PIRQH# Routing

                Offset(0x46),
                POLE, 1,        // INTE polarity
                POLF, 1,        // INTF polarity
                POLG, 1,        // INTG polarity
                POLH, 1,        // INTH polarity
                ENR8, 1,        // enable INTE~H routing by Rx44~Rx45.
                    , 1,
                ECOM, 1,

                Offset(0x4E),
                    , 3,
                EP74, 1,        // Enable 74/75 Access CMOS
                    , 4,

                Offset(0x50),
                    , 1,
                ESB3, 1,    // RX5001 EHCI1
                ESB2, 1,    // RX5002 USB3
                EIDE, 1,    // RX5003 EIDE
                EUSB, 1,    // RX5004 USB1
                ESB1, 1,    // RX5005 USB2
                USBD, 1,    // RX5006 USB Device Mode controller

                Offset(0x51),
                EKBC, 1,    // RX5100 Internal Keyboard controller
                KBCC, 1,    // RX5101 Internal KBC Configuration
                EPS2, 1,    // RX5102 Internal PS2 Mouse
                ERTC, 1,    // RX5103 Internal RTC
                SDIO, 1,    // RX5104 enable SDIO controller
                    , 2,

                Offset(0x55),
                    , 4,
                PIRA, 4,    // PCI IRQA
                PIRB, 4,    // PCI IRQB
                PIRC, 4,    // PCI IRQC
                    , 4,
                PIRD, 4,    // PCI IRQD

                Offset(0x58),
                    , 6,
                ESIA, 1,    // Enable Source Bridge IO APIC
                    , 1,

                Offset(0x81),   // Enable ACPI I/O
                    , 7,
                ENIO, 1,

                Offset(0x88),
                    , 7,
                IOBA, 9,        // Power Management I/O Base

                Offset(0x94),
                    , 5,
                PLLD, 1,    // RX9405 Internal PLL Reset During Suspend 0:Enable,1:Disable

                Offset(0xB0),
                    , 4,
                EU1E, 1,    // Embedded COM1
                EU2E, 1,    // Embedded COM2
                    , 2,

                Offset(0xB2),
                UIQ1, 4,    // UART1 IRQ
                UIQ2, 4,    // UART2 IRQ

                Offset(0xB4),
                U1BA, 7,    // UART1 I/O base address.
                    , 1,
                U2BA, 7,    // UART2 I/O base address.
                    , 1,

                Offset(0xB7),
                    , 3,
                UDFE, 1,    // UART DMA Funtion Enable

                Offset(0xB8),
                    , 2,
                DIBA, 14,   // UART DMA I/O Base Address

                Offset(0xBC),
                SPIB, 24,

                Offset(0xD0),
                    , 4,
                SMBA, 12,   // SMBus I/O Base (16-byte I/O space)

                Offset(0xD2),
                ENSM, 1,    // Enable SMBus IO
                    , 7,

                Offset(0xF6),
                REBD,   8,  //Internal Revision ID
            }

            Device(APCM)    // APIC MMIO
            {
                Name(_HID, EISAID("PNP0C02"))       // Hardware Device ID, Motherboard Resources
                Name(_UID, 0x1100)

                Name(_CRS, ResourceTemplate()
                {
                    Memory32Fixed(ReadWrite, 0xFEE00000, 0x00001000)  // Local APIC
                    Memory32Fixed(ReadWrite, 0xFEC00000, 0x00001000)  // IO APIC
                })
            }

            Device(PS2M)                            //PS2 Mouse
            {
                Name(_HID,EISAID("PNP0F13"))
                Name(_STA, 0xF)  // not present:  not used on XO
                Name(_CRS, ResourceTemplate () { IRQNoFlags () {12} })
                Name(_PRW, Package() {0x09, 0x04})
            }

            Device(PS2K)                             // PS2 Keyboard
            {
                    Name(_HID,EISAID("PNP0303"))
                    Name(_CID,EISAID("PNP030B"))    // Microsoft reserved PNP ID

                    Name(_STA,0xF)  // not present:  not used on XO

                    Name (_CRS, ResourceTemplate ()
                    {
                        IO (Decode16, 0x0060, 0x0060, 0x01, 0x01, )
                        IO (Decode16, 0x0064, 0x0064, 0x01, 0x01, )
                        IRQNoFlags () {1}
                    })
                    Name(_PRW, Package() {0x02, 0x04})
            }

            Device(DMAC)
            {
                Name(_HID, EISAID("PNP0200"))

                Name(_CRS,ResourceTemplate() {
                   IO(Decode16, 0x00, 0x00, 0, 0x10)     // Master DMA Controller
                   IO(Decode16, 0x81, 0x81, 0, 0x03)     // DMA Page Registers
                   IO(Decode16, 0x87, 0x87, 0, 0x01)
                   IO(Decode16, 0x89, 0x89, 0, 0x03)
                   IO(Decode16, 0x8F, 0x8F, 0, 0x01)
                   IO(Decode16, 0xC0, 0xC0, 0, 0x20)     // Slave DMA Controller
                   DMA(Compatibility,NotBusMaster,Transfer8) {4}   // Cascade channel
                })
            }

            Device(RTC)
            {
                Name(_HID,EISAID("PNP0B00"))

                Name(_CRS,ResourceTemplate()
                {
                  IO(Decode16, 0x70, 0x70, 0x00, 0x02)
                  IO(Decode16, 0x74, 0x74, 0x00, 0x02)
                  IRQNoFlags() {8}
                })
            }

            Device(PIC)
            {
                Name(_HID,EISAID("PNP0000"))
                Name(_CRS,ResourceTemplate() {
                    IO(Decode16,0x20,0x20,0x00,0x02)
                    IO(Decode16,0xA0,0xA0,0x00,0x02)
                })
            }

            Device(FPU)
            {
                Name(_HID,EISAID("PNP0C04"))
                Name(_CRS,ResourceTemplate() {
                    IO(Decode16,0xF0,0xF0,0x00,0x1)
                    IRQNoFlags(){13}
                })
            }

            Device(TMR)
            {
                Name(_HID,EISAID("PNP0100"))

                Name(_CRS, ResourceTemplate()
                {
                    IO(Decode16,0x40,0x40,0x00,0x04)
                    IRQNoFlags() {0}
                })
            }

            Device(SPKR)    // System Speaker
            {
                Name(_HID,EISAID("PNP0800"))
                Name(_CRS,ResourceTemplate() {
                    IO(Decode16,0x61,0x61,0x01,0x01)
                })
            }

            Name (ICRS, ResourceTemplate ()
            {
                IRQ (Level, ActiveLow, Shared) // The flags is the value of Byte 3 of IRQ Description Definition
                    { }                        // The value decides the value of Byte 1 and byte 2 of IRQ Description Definition
            })

            Name(PRSA, ResourceTemplate()
            {
                IRQ(Level, ActiveLow, Shared)
                {3, 4, 5, 6, 7, 10, 11, 12, 14, 15}
            })

            Device(LNKA)    {
                Name(_HID, EISAID("PNP0C0F"))       // PCI interrupt link
                Name(_UID, 1)
                Method(_STA, 0)
                {
                    If(LEqual(\_SB.PCI0.VT86.PIRA, 0x00))
                    {
                        Return(0x09)        // disabled
                    } Else {
                        Return(0x0B)        // enabled, but no UI
                    }
                }

                Method(_PRS)
                {
                    Return(PRSA)
                }

                Method(_DIS)
                {
                    Store(0x0, \_SB.PCI0.VT86.PIRA)
                }

                Method(_CRS)
                {
                    CreateWordField (ICRS, 1, IRA0)
                    Store (1, Local1)
                    ShiftLeft (Local1, \_SB.PCI0.VT86.PIRA, IRA0)
                    Return (ICRS)
                }

                Method(_SRS, 1) {
                    CreateWordField (Arg0, 1, IRA)  // Byte 1 and Byte 2 in the IRQ Descriptor Definition
                    FindSetRightBit (IRA, Local0)
                    Decrement (Local0)
                    Store (Local0, \_SB.PCI0.VT86.PIRA)
                }
            }

            Device(LNKB)    {
                Name(_HID, EISAID("PNP0C0F"))       // PCI interrupt link
                Name(_UID, 2)
                Method(_STA, 0)
                {
                    If(LEqual(\_SB.PCI0.VT86.PIRB, 0x00))
                    {
                        Return(0x09)        // disabled
                    } Else {
                        Return(0x0B)        // enabled, but no UI
                    }
                }

                Method(_PRS)
                {
                    Return(PRSA)
                }

                Method(_DIS)
                {
                    Store(0x0, \_SB.PCI0.VT86.PIRB)
                }

                Method(_CRS)
                {
                    CreateWordField (ICRS, 1, IRA0)
                    Store (1, Local1)
                    ShiftLeft (Local1, \_SB.PCI0.VT86.PIRB, IRA0)
                    Return (ICRS)
                }

                Method(_SRS, 1) {
                    CreateWordField (Arg0, 1, IRA)  // Byte 1 and Byte 2 in the IRQ Descriptor Definition
                    FindSetRightBit (IRA, Local0)
                    Decrement (Local0)
                    Store (Local0, \_SB.PCI0.VT86.PIRB)
                }
            }


            Device(LNKC)    {
                Name(_HID, EISAID("PNP0C0F"))       // PCI interrupt link
                Name(_UID, 3)
                Method(_STA, 0)
                {
                    If(LEqual(\_SB.PCI0.VT86.PIRC, 0x00))
                    {
                        Return(0x09)        // disabled
                    } Else {
                        Return(0x0B)        // enabled, but no UI
                    }
                }

                Method(_PRS)
                {
                    Return(PRSA)
                }

                Method(_DIS)
                {
                    Store(0x0, \_SB.PCI0.VT86.PIRC)
                }

                Method(_CRS)
                {
                    CreateWordField (ICRS, 1, IRA0)
                    Store (1, Local1)
                    ShiftLeft (Local1, \_SB.PCI0.VT86.PIRC, IRA0)
                    Return (ICRS)
                }

                Method(_SRS, 1) {
                    CreateWordField (Arg0, 1, IRA)  //Byte 1 and Byte 2 in the IRQ Descriptor Definition
                    FindSetRightBit (IRA, Local0)
                    Decrement (Local0)
                    Store (Local0, \_SB.PCI0.VT86.PIRC)
                }
            }

            Device(LNKD)    {
                Name(_HID, EISAID("PNP0C0F"))       // PCI interrupt link
                Name(_UID, 4)
                Method(_STA, 0)
                {
                    If(LEqual(\_SB.PCI0.VT86.PIRD, 0x00))
                    {
                        Return(0x09)        // disabled
                    } Else {
                        Return(0x0B)        // enabled, but no UI
                    }
                }

                Method(_PRS)
                {
                    Return(PRSA)
                }

                Method(_DIS)
                {
                    Store(0x0, \_SB.PCI0.VT86.PIRD)
                }

                Method(_CRS)
                {
                    CreateWordField (ICRS, 1, IRA0)
                    Store (1, Local1)
                    ShiftLeft (Local1, \_SB.PCI0.VT86.PIRD, IRA0)
                    Return (ICRS)
                }

                Method(_SRS, 1) {
                    CreateWordField (Arg0, 1, IRA)  //Byte 1 and Byte 2 in the IRQ Descriptor Definition
                    FindSetRightBit (IRA, Local0)
                    Decrement (Local0)
                    Store (Local0, \_SB.PCI0.VT86.PIRD)
                }
            }

            Device(LNKE)    {
                Name(_HID, EISAID("PNP0C0F"))       // PCI interrupt link
                Name(_UID, 5)
                Method(_STA, 0)
                {
                    If(LEqual(\_SB.PCI0.VT86.PIRE, 0x00))
                    {
                        Return(0x09)        // disabled
                    } Else {
                        Return(0x0B)        // enabled, but no UI
                    }
                }

                Method(_PRS)
                {
                    Return(PRSA)
                }

                Method(_DIS)
                {
                    Store(0x0, \_SB.PCI0.VT86.PIRE)
                }

                Method(_CRS)
                {
                    CreateWordField (ICRS, 1, IRA0)
                    Store (1, Local1)
                    ShiftLeft (Local1, \_SB.PCI0.VT86.PIRE, IRA0)
                    Return (ICRS)
                }

                Method(_SRS, 1) {
                    CreateWordField (Arg0, 1, IRA)  //Byte 1 and Byte 2 in the IRQ Descriptor Definition
                    FindSetRightBit (IRA, Local0)
                    Decrement (Local0)
                    Store (Local0, \_SB.PCI0.VT86.PIRE)
                    Store(One,ENR8)
                    Store(Zero,POLE)
                }
            }

            Device(LNKF)    {
                Name(_HID, EISAID("PNP0C0F"))       // PCI interrupt link
                Name(_UID, 6)
                Method(_STA, 0)
                {
                    If(LEqual(\_SB.PCI0.VT86.PIRF, 0x00))
                    {
                        Return(0x09)        // disabled
                    } Else {
                        Return(0x0B)        // enabled, but no UI
                    }
                }

                Method(_PRS)
                {
                    Return(PRSA)
                }

                Method(_DIS)
                {
                    Store(0x0, \_SB.PCI0.VT86.PIRF)
                }

                Method(_CRS)
                {
                    CreateWordField (ICRS, 1, IRA0)
                    Store (1, Local1)
                    ShiftLeft (Local1, \_SB.PCI0.VT86.PIRF, IRA0)
                    Return (ICRS)
                }

                Method(_SRS, 1) {
                    CreateWordField (Arg0, 1, IRA)  //Byte 1 and Byte 2 in the IRQ Descriptor Definition
                    FindSetRightBit (IRA, Local0)
                    Decrement (Local0)
                    Store (Local0, \_SB.PCI0.VT86.PIRF)
                    Store(One,ENR8)
                    Store(Zero,POLF)
                }
            }

            Device(LNK0)    {
                Name(_HID, EISAID("PNP0C0F"))       // PCI interrupt link
                Name(_UID, 7)
                Method(_STA, 0)
                {
                    If(LEqual(\_SB.PCI0.VT86.PIRG, 0x00))
                    {
                        Return(0x09)        // disabled
                    } Else {
                        Return(0x0B)        // enabled, but no UI
                    }
                }

                Method(_PRS)
                {
                    Return(PRSA)
                }

                Method(_DIS)
                {
                    Store(0x0, \_SB.PCI0.VT86.PIRG)
                }

                Method(_CRS)
                {
                    CreateWordField (ICRS, 1, IRA0)
                    Store (1, Local1)
                    ShiftLeft (Local1, \_SB.PCI0.VT86.PIRG, IRA0)
                    Return (ICRS)
                }

                Method(_SRS, 1) {
                    CreateWordField (Arg0, 1, IRA)  //Byte 1 and Byte 2 in the IRQ Descriptor Definition
                    FindSetRightBit (IRA, Local0)
                    Decrement (Local0)
                    Store (Local0, \_SB.PCI0.VT86.PIRG)
                    Store(One,ENR8)
                    Store(Zero,POLG)
                }
            }

            Device(LNK1) {
                Name(_HID, EISAID("PNP0C0F"))       // PCI interrupt link
                Name(_UID, 8)
                Method(_STA, 0)
                {
                    If(LEqual(\_SB.PCI0.VT86.PIRH, 0x00))
                    {
                        Return(0x09)        // disabled
                    } Else {
                        Return(0x0B)        // enabled, but no UI
                    }
                }

                Method(_PRS)
                {
                    Return(PRSA)
                }

                Method(_DIS)
                {
                    Store(0x0, \_SB.PCI0.VT86.PIRH)
                }

                Method(_CRS)
                {
                    CreateWordField (ICRS, 1, IRA0)
                    Store (1, Local1)
                    ShiftLeft (Local1, \_SB.PCI0.VT86.PIRH, IRA0)
                    Return (ICRS)
                }

                Method(_SRS, 1) {
                    CreateWordField (Arg0, 1, IRA)  //Byte 1 and Byte 2 in the IRQ Descriptor Definition
                    FindSetRightBit (IRA, Local0)
                    Decrement (Local0)
                    Store (Local0, \_SB.PCI0.VT86.PIRH)
                    Store(One,ENR8)
                    Store(Zero,POLH)
                }
            }

            Mutex (MUEC, 0x00)
            OperationRegion (ECCP, SystemIO, 0x068, 0x05)

            // NB -- the EC routines all return 0 for failure

            Field (ECCP, ByteAcc, NoLock, Preserve)
            {
                ECDA,   8,   // 0x68
                    ,   8,
                    ,   8,
                    ,   8,
                ECCM,   8,   // 0x6c
            }

            // force clear OBF by reading/discarding 0x68
            Method (OBFZ, 0, Serialized)
            {
                Store (100, Local0)
                While (LAnd (Decrement (Local0), And (ECCM, 1)))
                {
                   Store (ECDA, Local1)
                   Sleep(1)
                }
                Return (LNotEqual (Local0, Zero))
            }

            // wait for IBF == 0
            Method (IBFZ, 0, Serialized)
            {
                Store (100, Local0)
                While (LAnd (Decrement (Local0), And (ECCM, 2)))
                {
                   Sleep(1)
                }
                Return (LNotEqual (Local0, Zero))
            }

            // wait for IBF == 1
            Method (IBFN, 0, Serialized)
            {
                Store (100, Local0)
                While (LAnd (Decrement (Local0), LNot (And (ECCM, 2))))
                {
                   Sleep(1)
                }
                Return (LNotEqual (Local0, Zero))
            }

            // wait for OBF == 1
            Method (OBFN, 0, Serialized)
            {
                Store (100, Local0)
                While (LAnd (Decrement (Local0), LNot (And (ECCM, 1))))
                {
                   // UPUT (0x38)
                   // UDOT (ECCM)
                   Sleep(1)
                }
                Return (LNotEqual (Local0, Zero))
            }

            // EC read byte helper
            Method (ECRB, 0, NotSerialized)
            {
                if (OBFN ()) { Return(ECDA) }
                Return (Ones)
            }

            // EC command helper
            Method (ECWC, 1, NotSerialized)
            {
                UPUT (0x21)  // !
                UDOT (Arg0)
                if (OBFZ ()) {
                    // UPUT (0x35)
                    if (IBFZ ()) {
                        // UPUT (0x36)
                        Store (Arg0, ECCM)          // write the command to 0x6c
                        if (IBFZ ()) {
                            // UPUT (0x37)
                            Return (One)
                        }
                    }
                }
                Return(Zero)
            }

            // EC command (zero args)
            Method (ECW0, 2, NotSerialized)
            {
                If (Acquire (MUEC, 0xFFFF)) { Return (One) }

                if (ECWC (Arg0)) {
                    Release(MUEC)
                    Return(One)
                }
                UPUT (0x2a)  // *
                Release(MUEC)
                Return (Zero)
            }

            // EC command - 1 arg
            Method (ECW1, 2, NotSerialized)
            {
                If (Acquire (MUEC, 0xFFFF)) { Return (One) }

                if (ECWC (Arg0)) {
                    if (IBFZ ()) {
                        UPUT (0x2b)  // +
                        UDOT (Arg1)
                        Store (Arg1, ECDA)          // write the data to 0x68
                        Release(MUEC)
                        Return(One)
                    }
                }
                UPUT (0x2a)  // *
                Release(MUEC)
                Return (Zero)
            }

            // EC command - 2 args
            Method (ECW2, 3, NotSerialized)
            {
                If (Acquire (MUEC, 0xFFFF)) { Return (One) }

                if (ECWC (Arg0)) {
                    if (IBFZ ()) {
                        UPUT (0x2b)  // +
                        UDOT (Arg1)
                        Store (Arg1, ECDA)          // write the data to 0x68
                        if (IBFZ ()) {
                            UPUT (0x2b)  // +
                            UDOT (Arg2)
                            Store (Arg2, ECDA)      // write the next data to 0x68
                            Release(MUEC)
                            Return(One)
                        }
                    }
                }
                UPUT (0x2a)  // *
                Release(MUEC)
                Return (Zero)
            }

            // EC command - no arg, 1 return byte
            Method (ECR1, 1, NotSerialized)
                {

                If (Acquire (MUEC, 0xFFFF)) { Return (One) }
                // UPUT (0x4c) // L

                If (ECWC (Arg0)) {
                    // UPUT (0x31)
                        Store (10, Local0)                     // Ten retries
                        While (Decrement(Local0)) {
                            // UPUT (0x32)
                            Store (ECRB (), Local1)
                            If (LNotEqual (Local1, Ones))
                            {
                                UPUT (0x3d)  // =
                                UDOT (Local1)
                                Release(MUEC)
                                Return (Local1)                 // Success
                            }
                            UPUT (0x2c)  // ,
                        }
                }
                UPUT (0x2a)  // *
                Release(MUEC)
                Return (Ones)
            }

            // EC command - one arg, one return byte
            Method (ECWR, 2, NotSerialized)
            {
                Store (10, Local0)                     // Ten retries

                If (Acquire (MUEC, 0xFFFF)) { Return (One) }

                If (ECWC (Arg0)) {
                    if (IBFZ ()) {
                        UPUT (0x2b)  // +
                        UDOT (Arg1)
                        Store (Arg1, ECDA)          // write the data to 0x68
                        While (Decrement(Local0)) {
                            Store (ECRB (), Local1)
                            If (LNotEqual (Local1, Ones))
                            {
                                UPUT (0x3d)  // =
                                UDOT (Local1)
                                Release(MUEC)
                                Return (Local1)                 // Success
                            }
                            UPUT (0x2c)  // ,
                        }
                    }
                }
                UPUT (0x2a)  // *
                Release(MUEC)
                Return (Ones)
            }

            Mutex (ACMX, 0x00)

            Device (AC) {  /* AC adapter */
                Name (_HID, "ACPI0003")
                Name (_PCL, Package (0x01) { _SB })  // Power consumer list - points to main system bus

                Method (_PSR, 0, NotSerialized)
                {
                    If (LNot (Acquire (ACMX, 5000)))
                    {
                        UPUT (0x70)  // p
                       // Store (ECRD (0xFA40), Local0)
                       Store (ECR1 (0x15), Local0) // CMD_READ_BATTERY_STATUS
                       Release (ACMX)
                    }

                    // If (And (Local0, One))
                    If (And (Local0, 0x10))
                    {
                        Return (One)
                    } Else {
                        Return (Zero)
                    }
                }

                Name (_STA, 0x0F)
            }

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

            Device (BATT) {
                Name (_HID, EisaId ("PNP0C0A"))
                Name (_UID, One)
                Name (_PCL, Package (0x01)
                {
                    _SB
                })

                Method (_STA, 0, NotSerialized)   // Battery Status
                {

                    If (LNot (Acquire (ACMX, 5000)))
                    {
                        UPUT (0x73)  // s
                        // Store (ECRD (0xFAA4), Local0)
                        Store (ECR1 (0x15), Local0) // CMD_READ_BATTERY_STATUS
                        Release (ACMX)
                    }

                    If (And (Local0, One))  // ECRD(0xfaa4) & 0x01 => Battery inserted
                    {
                        Return (0x1F)
                    } Else {
                        Return (0x0F)
                    }
                }

                Method (_BIF, 0, NotSerialized)         // Battery Info
                {
                    If (LNot (Acquire (ACMX, 5000)))
                    {
                        // Store (ECRD (0xFB5F), Local0)
                        Store (ECR1 (0x2c), Local0)   // CMD_READ_BATTERY_TYPE
                        // Store (ECRD (0xF929), Local1) // FIXME -- BAT_SOC_WARNNING
                        Store (15, Local1) // EC hard-codes this (BAT_SOC_WARNNING)
                        Switch (Local0)
                        {
                            Case (0x11)
                            {
                                UPUT (0x42)  // B
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
                                Store ("NiMH", Index (BIFP, 11))
                                Store ("GoldPeak ", Index (BIFP, 0x0C))
                                UPUT (0x62)  // b
                            }
                            Case (0x12)
                            {
                                UPUT (0x44)  // D
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
                                Store ("LiFePO4", Index (BIFP, 11))
                                Store ("GoldPeak ", Index (BIFP, 0x0C))
                                UPUT (0x64)  // d
                            }
                            Case (0x22)
                            {
                                UPUT (0x43)  // C
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
                                Store ("LiFePO4", Index (BIFP, 11))
                                Store ("BYD ", Index (BIFP, 0x0C))
                                UPUT (0x63)  // c
                            }
                        }
                        UPUT (0x49)  // I

                        Release (ACMX)
                    }

                    Return (BIFP)
                }

                Method (_BST, 0, NotSerialized)
                {
                    If (LNot (Acquire (ACMX, 5000)))
                    {
                        UPUT (0x74)  // t
                        // If (And (ECRD (0xFAA5), One))
                        Store (ECR1(0x15), Local0)  // CMD_READ_BATTERY_STATUS
                        If (And (Local0, 0x20))
                        {
                            Store (0x02, Local1)  // charging
                        }
                        ElseIf (And (Local0, 0x40)) //
                        {
                            Store (One, Local1)  // discharging
                        }

                        Sleep (15)
                        // Store (ECRD (0xF910), Local0)
                        Store (ECR1 (0x16), Local0)  // CMD_READ_SOC
                        If (LLess (Local0, 15))
                        {
                            Or (Local1, 4, Local1)  // critical
                        }

                        Store (Local1, Index (BSTP, Zero))
                        Sleep (15)

                        // Switch (ECRD (0xFB5F))
                        Switch (ECR1 (0x2c))   // CMD_READ_BATTERY_TYPE
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

            Device(RMSC) {   // all "PNP0C02" devices- pieces that don't fit anywhere else
                Name(_HID,EISAID("PNP0C02"))        // Generic motherboard devices
                Name (_UID, 0x13)

                Name(CRS,ResourceTemplate(){

                    IO(Decode16,0x10,0x10,0x00,0x10)
                    IO(Decode16,0x22,0x22,0x00,0x1E)
                    IO(Decode16,0x44,0x44,0x00,0x1C)
                    IO(Decode16,0x62,0x62,0x00,0x02)
                    IO(Decode16,0x65,0x65,0x00,0x0B)
                    IO(Decode16,0x72,0x72,0x00,0x02)
                    IO(Decode16,0x76,0x76,0x00,0x09)
                    IO(Decode16,0x80,0x80,0x00,0x01)
                    IO(Decode16,0x84,0x84,0x00,0x03)
                    IO(Decode16,0x88,0x88,0x00,0x01)
                    IO(Decode16,0x8c,0x8c,0x00,0x03)
                    IO(Decode16,0x90,0x90,0x00,0x02)
                    IO(Decode16,0x92,0x92,0x00,0x01)                    // INIT & Fast A20 port
                    IO(Decode16,0x93,0x93,0x00,0x0C)
                    IO(Decode16,0xA2,0xA2,0x00,0x1E)
                    IO(Decode16,0xE0,0xE0,0x00,0x10)
                    IO(Decode16,0x3E0,0x3E0,0x00,0x8)

                    // Reserve  4D0 and 4D1 for IRQ edge/level control port
                    IO(Decode16, 0x4D0,0x4D0,0x00,0x2)
                    // ACPI IO base address allocation
                    IO(Decode16, 0, 0, 0, 0, IO0)
                    // SMBus I/O space if applicable
                    IO(Decode16, 0, 0, 0, 0, IO1)
                    // SPI Memory Map IO Base
                    Memory32Fixed(ReadWrite, 0x00000000, 0x00000000, MEM0)
                })

                Method(_CRS, 0)
                {
                    If(LEqual(\_SB.PCI0.VT86.ENIO, 0x01))   // If we should privide the DSDT, ACPI IO must be enabled.
                    {
                        CreateWordField(CRS, ^IO0._MIN, MIN0)
                        CreateWordField(CRS, ^IO0._MAX, MAX0)
                        CreateByteField(CRS, ^IO0._LEN, LEN0)
                        Store(\_SB.PCI0.VT86.IOBA, Local0)
                        ShiftLeft(Local0, 7, Local0)
                        Store(Local0, MIN0)
                        Store(Local0, MAX0)
                        Store(0x80, LEN0)
                    }

                    If(LEqual(\_SB.PCI0.VT86.ENSM, 0x01))
                    {
                        CreateWordField(CRS, ^IO1._MIN, MIN1)
                        CreateWordField(CRS, ^IO1._MAX, MAX1)
                        CreateByteField(CRS, ^IO1._LEN, LEN1)
                        Store(\_SB.PCI0.VT86.SMBA, Local0)
                        ShiftLeft(Local0, 4, Local0)
                        Store(Local0, MIN1)
                        Store(Local0, MAX1)
                        Store(0x10, LEN1)   // Length: 16 Byte
                    }

                    If(LNotEqual(\_SB.PCI0.VT86.SPIB, 0x00))
                    {
                        CreateDWordField(CRS, ^MEM0._BAS, BAS2)
                        CreateDWordField(CRS, ^MEM0._LEN, LEN2)
                        Store(\_SB.PCI0.VT86.SPIB, Local0)
                        ShiftLeft(Local0, 8, Local0)
                        Store(Local0, BAS2)
                        Store(0x100, LEN2)
                    }

                    Return(CRS)
                }
            }

        } // End of (VT86)

        Name(PICM, Package(){
            // VIA VGA Device(Integrated Graphics Device)
            Package(){0x0001ffff, 0, \_SB.PCI0.VT86.LNKA, 0},   // VGA, INTA

            //PCI Slot 1
            Package(){0x0008ffff, 0, \_SB.PCI0.VT86.LNKA, 0},   // Slot 1, INTA
            Package(){0x0008ffff, 1, \_SB.PCI0.VT86.LNKA, 0},   // Slot 1, INTB
            Package(){0x0008ffff, 2, \_SB.PCI0.VT86.LNKA, 0},   // Slot 1, INTC
            Package(){0x0008ffff, 3, \_SB.PCI0.VT86.LNKA, 0},   // Slot 1, INTD

            //PCI Slot 2
            Package(){0x0009ffff, 0, \_SB.PCI0.VT86.LNKA, 0},   // Slot 2, INTA
            Package(){0x0009ffff, 1, \_SB.PCI0.VT86.LNKA, 0},   // Slot 2, INTB
            Package(){0x0009ffff, 2, \_SB.PCI0.VT86.LNKA, 0},   // Slot 2, INTC
            Package(){0x0009ffff, 3, \_SB.PCI0.VT86.LNKA, 0},   // Slot 2, INTD

            //PCI Slot 3
            Package(){0x000Affff, 0, \_SB.PCI0.VT86.LNKA, 0},   // Slot 3, INTA
            Package(){0x000Affff, 1, \_SB.PCI0.VT86.LNKA, 0},   // Slot 3, INTB
            Package(){0x000Affff, 2, \_SB.PCI0.VT86.LNKA, 0},   // Slot 3, INTC
            Package(){0x000Affff, 3, \_SB.PCI0.VT86.LNKA, 0},   // Slot 3, INTD

            // USB Device Controller
            Package(){0x000Bffff, 0, \_SB.PCI0.VT86.LNKA, 0},

            // SDIO Controller
            Package(){0x000cffff, 0, \_SB.PCI0.VT86.LNKA, 0},
            // SD $ MS Controller
            Package(){0x000dffff, 0, \_SB.PCI0.VT86.LNKB, 0},
            // CE-ATA $ NF Controller(Card Boot)
            Package(){0x000effff, 0, \_SB.PCI0.VT86.LNKC, 0},
            // VIA VX800 IDE
            Package(){0x000fffff, 0, \_SB.PCI0.VT86.LNKB, 0},

            // VIA UHCI USB1 Device
            Package(){0x0010ffff, 0, \_SB.PCI0.VT86.LNKA, 0},
            // VIA UHCI USB2 Device
            Package(){0x0010ffff, 1, \_SB.PCI0.VT86.LNKB, 0},
            // VIA UHCI USB3 Device
            Package(){0x0010ffff, 2, \_SB.PCI0.VT86.LNKC, 0},
            // VIA EHCI USB 2.0 Device
            Package(){0x0010ffff, 3, \_SB.PCI0.VT86.LNKD, 0},

            // SB HDAC(Azalia) Audio
            Package(){0x0014ffff, 0, \_SB.PCI0.VT86.LNKA, 0},   // HD Audio, INTA
        })

        Name(APIC, Package(){
            // VIA VGA Device(Integrated Graphics Device)
            Package(){0x0001ffff, 0, 0, 0x10},

            //PCI Slot 1
            Package(){0x0008ffff, 0, 0, 0x10},
            Package(){0x0008ffff, 1, 0, 0x10},
            Package(){0x0008ffff, 2, 0, 0x10},
            Package(){0x0008ffff, 3, 0, 0x10},

            //PCI Slot 2
            Package(){0x0009ffff, 0, 0, 0x10},
            Package(){0x0009ffff, 1, 0, 0x10},
            Package(){0x0009ffff, 2, 0, 0x10},
            Package(){0x0009ffff, 3, 0, 0x10},

            //PCI Slot 3
            Package(){0x000Affff, 0, 0, 0x10},
            Package(){0x000Affff, 1, 0, 0x10},
            Package(){0x000Affff, 2, 0, 0x10},
            Package(){0x000Affff, 3, 0, 0x10},

            // USB Device Controller
            Package(){0x000Bffff, 0, 0, 0x13},  // USBD, INTA

            // SDIO Controller
            Package(){0x000cffff, 0, 0, 0x16},  // SDIO, INTA
            // SD $ MS Controller
            Package(){0x000dffff, 0, 0, 0x17},  // Card Reader, INTA
            // CE-ATA $ NF Controller(Card Boot)
            Package(){0x000effff, 0, 0, 0x14},  // Card Boot(NAND Flash), INTA
            // VIA VX800 IDE
            Package(){0x000fffff, 0, 0, 0x15},  //IDE, INTA

            // VIA UHCI USB1 Device
            Package(){0x0010ffff, 0, 0, 0x14},
            // VIA UHCI USB2 Device
            Package(){0x0010ffff, 1, 0, 0x16},
            // VIA UHCI USB3 Device
            Package(){0x0010ffff, 2, 0, 0x15},
            // VIA EHCI USB 2.0 Device
            Package(){0x0010ffff, 3, 0, 0x17},

            // SB HDAC(Azalia) Audio
            Package(){0x0014ffff, 0, 0, 0x11},  //HD Audio , INTA

        }) // end of APIX

        Method(_PRT, 0, NotSerialized)
        {
            If(LNot(PICF))
            {
                //PIC
                Return(PICM)
            } Else {
                //APIC
                Return(APIC)
            }
        }

        Device(P2PB)
        {
            Name (_ADR, 0x00130000)

            OperationRegion(RP2P,PCI_Config,0x00,0x100)
            Field(RP2P,ByteAcc,NoLock,Preserve){
                Offset(0x00),
                VID,   16,
                Offset(0x04),
                CMDR, 3,
                Offset(0x19),
                BUS1, 8,
            }

            Method(_BBN,0)
            {
                Return(BUS1)
            }

            Method(_STA, 0)
            {
                If(LNotEqual(\_SB.PCI0.P2PB.VID, 0x1106)) {
                    Return(0x00)
                } Else {
                    If(LEqual(\_SB.PCI0.P2PB.CMDR, 0x00)) {
                        Return(0x0D)
                    } Else {
                        Return(0x0F)        // present, enabled, functioning
                    }
                }
            }

            Name(PIC4, Package(){
                Package(){0x0003ffff, 0,\_SB.PCI0.VT86.LNKA , 0},
                Package(){0x0003ffff, 1,\_SB.PCI0.VT86.LNKA , 0},
                Package(){0x0003ffff, 2,\_SB.PCI0.VT86.LNKA , 0},
                Package(){0x0003ffff, 3,\_SB.PCI0.VT86.LNKA , 0},

                Package(){0x0004ffff, 0,\_SB.PCI0.VT86.LNKA , 0},
                Package(){0x0004ffff, 1,\_SB.PCI0.VT86.LNKA , 0},
                Package(){0x0004ffff, 2,\_SB.PCI0.VT86.LNKA , 0},
                Package(){0x0004ffff, 3,\_SB.PCI0.VT86.LNKA , 0},

                Package(){0x0005ffff, 0,\_SB.PCI0.VT86.LNKA , 0},
                Package(){0x0005ffff, 1,\_SB.PCI0.VT86.LNKA , 0},
                Package(){0x0005ffff, 2,\_SB.PCI0.VT86.LNKA , 0},
                Package(){0x0005ffff, 3,\_SB.PCI0.VT86.LNKA , 0},
            })

            Name(API4, Package(){
                Package(){0x0003ffff, 0, 0, 0x10},
                Package(){0x0003ffff, 1, 0, 0x10},
                Package(){0x0003ffff, 2, 0, 0x10},
                Package(){0x0003ffff, 3, 0, 0x10},

                Package(){0x0004ffff, 0, 0, 0x10},
                Package(){0x0004ffff, 1, 0, 0x10},
                Package(){0x0004ffff, 2, 0, 0x10},
                Package(){0x0004ffff, 3, 0, 0x10},

                Package(){0x0005ffff, 0, 0, 0x10},
                Package(){0x0005ffff, 1, 0, 0x10},
                Package(){0x0005ffff, 2, 0, 0x10},
                Package(){0x0005ffff, 3, 0, 0x10},
            })

            Method(_PRT, 0x0, NotSerialized)
            {
                If(LNot(PICF))
                {
                    Return(PIC4)
                } Else {
                    Return(API4)
                }
            }

            Method(_PRW, 0x00, NotSerialized)
            {
                Return(Package(){0x05,4})   //PME#
            }
            Device(P4D3)
            {
                Name(_ADR, 0x00030000)
            }
        }   // Device(P2PB)

        Device (EC) {
            Name(_HID,EISAID("PNP0C09"))                    // Embedded controller ID
            Name (_PRW, Package (0x02) {  0x01, 0x04 })     // Event 01, wakes from S4

            Method(_INI, 0)
            {
                UPUT (0x49)  // I
                Store (One, GPWK)            // Enable gpwake
            }

        }  // Device(EC)

        Device (EBK) {
            Name (_HID, "XO15EBK")
            Name (_PRW, Package (0x02) {  0x0A, 0x04 })     // Event 0A, wakes from S4

            Method(_INI, 0)
            {
                Store (One, THRM)
                Store (GPI9, TPOL)  // init edge detect from current state
            }

            Method(EBK) {
                If (GPI9) { // non-zero --> switch is open
                    UPUT (0x65)                   // e
                } Else {
                    UPUT (0x45)                   // E
                }
                If (LNotEqual(GPI9, TPOL)) {
                    Store (GPI9, TPOL)  // (re)init edge detect
                }
                Return(GPI9)
            }
        }  // Device(EBK)

        Device (LID) {
            Name (_HID, EisaId ("PNP0C0D"))
            Name (_PRW, Package (0x02) {  0x0B, 0x04 })     // Event 0B, wakes from S4

            Method(_INI, 0)
            {
                Store (GPI7, LPOL)  // init edge detect from current state
            }


            Method(_LID) {
                If (GPI7) { // non-zero --> switch (and lid) is open
                    UPUT (0x6c)                   // l
                } Else {
                    UPUT (0x4c)                   // L
                }

                If (LNotEqual(GPI7, LPOL)) {
                    Store (GPI7, LPOL)  // (re)init edge detect
                }

                Return(GPI7)
            }

        }  // Device(LID)

        Device(HDAC)
        {
            Name(_ADR, 0x00140000)

            OperationRegion(RHDA,PCI_Config,0x00,0x100)
            Field(RHDA,ByteAcc,NoLock,Preserve){
                Offset(0x00),
                VID,   16,
                Offset(0x04),
                CMDR, 3,
            }

            Method(_STA, 0)
            {
                If(LNotEqual(\_SB.PCI0.HDAC.VID, 0x1106)) {
                    Return(0x00)
                } Else {
                    If(LEqual(\_SB.PCI0.HDAC.CMDR, 0x00)) {
                        Return(0x0D)
                    } Else {
                        Return(0x0F)        // present, enabled, functioning
                    }
                }
            }

            Method(_PRW)
            {
                Return (Package(){0xD, 4})
            }
        }//Device(HDAC)

    } // Device(PCI0)

    //-----------------------------------------------------------------------
    // System board extension Device node for ACPI BIOS
    //-----------------------------------------------------------------------
    /*

    Procedure:      RMEM

    Description:    System board extension Device node for ACPI BIOS
    Place the device under \_SB scope, As per Msft the MEM
    Device is used to reserve Resources that are decoded out of PCI Bus
    Important consideration :
    Logic to reserve the memory within 0xC0000 - 0xFFFFF Extended BIOS area is based on assumption,
    that the BIOS Post has detected all expansion ROMs in the region and made their memory ranges
    shadowable ( copied to RAM at the same address, for performance reasons).
    The rest of the region is left non-Shadowable, hence no memory is decoded there.
    Such region is decoded to PCI bus (to be reserved in PCI0._CRS)
    Whatever memory is Shadowed, thus, decoded as non "FF"s, is required to be reserved in "SYSM"
    System board extension Device node, unless is not already reserved by some of PCI Device drivers.
    There have been observed the difference of how Win9x & Win2000
    OSes deal with Expansion ROM memory. Win9x Device drivers are tend to claim its expension ROMs regions as used
    by the device; Win2000 never use such ROM regions for its devices. Therefore there can be different
    approach used for different OSes in reservation unclaimed memory in "SYSM" Device node.
    is forwarded to PCI Bus

    Input: Nothing

    Output: _CRS buffer

    **************************************************************************/

    Device(RMEM) {
        Name(_HID, EISAID("PNP0C01"))       // Hardware Device ID, System Board
        Name(_UID, 1)
        Name(CRS, ResourceTemplate()
        {
            // Base Address 0 - 0x9FFFF , 640k DOS memory
            Memory32Fixed(ReadWrite,0x0000,  0xA0000 )      //Writeable
            // Shadow RAM1, C0000 - E0000, 128k Expansion BIOS
            Memory32Fixed(ReadOnly, 0x00000, 0x00000, RAM1) //Non-writeable
            // Shadow RAM2, E0000 - 1M, 128k System BIOS
            Memory32Fixed(ReadOnly, 0xE0000, 0x20000, RAM2) //Non-writeable
            // Base Address 1M - Top of system present memory
            Memory32Fixed(ReadWrite,0x100000,0x00000, RAM3) //Writeable
        })

        Method (_CRS, 0)
        {
            CreateDWordField(CRS, ^RAM1._BAS, BAS1)
            CreateDWordField(CRS, ^RAM1._LEN, LEN1)
            CreateDWordField(CRS, ^RAM2._BAS, BAS2)
            CreateDWordField(CRS, ^RAM2._LEN, LEN2)
            CreateDWordField(CRS, ^RAM3._LEN, LEN3)

            //RAM3
            Store(\_SB.PCI0.MEMC.LTMA, Local0)
            ShiftLeft(Local0, 0x10, Local2)
            Store(\_SB.PCI0.MEMC.ENIG, Local1)
            If(LEqual(Local1, 1))   // Check whether the Internal Graphic is enabled.
            {
                Add(\_SB.PCI0.MEMC.FBSZ, 2, Local3)
                ShiftLeft(1, Local3, Local4)
                ShiftLeft(Local4, 0x14, Local4)
                Subtract(Local2, Local4, Local2)    // Subtract the Framebuffer Size
            }
            Store(\_SB.PCI0.MEMC.ENTS, Local1)
            If(LEqual(Local1, 1))   // Check Whether the Top SMRAM Segment is Enabled
            {
                ShiftLeft(1, \_SB.PCI0.MEMC.TSMS, Local5)
                ShiftLeft(Local5, 0x14, Local5)
                Subtract(Local2, Local5, Local2)    // Subtract Top SM RAM Size
            }
            Subtract(Local2, 0x100000, LEN3)

            Return(CRS)
        }
    }

}//Scope(\_SB)
}
