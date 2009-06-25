DefinitionBlock ("dsdt.aml",      // AML file name
                 "DSDT",          // Table signature, DSDT
                 0x01,            // Compliance Revision
                 "OLPC",          // OEM ID
                 "XO-1.5  ",      // Table ID
                 0x00000001)      // OEM Revision
{

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
    Scope(\_PR) {
        Processor(\_PR.CPU0,0x00,0x00000410,0x06){}
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

    OperationRegion(\GPST, SystemIO, 0x0420, 0x2)
    Field(\GPST, ByteAcc, NoLock, Preserve) {
        GS00,1,
        GS01,1,
        GS02,1,
        GS03,1,
        GS04,1,
        GS05,1,
        GS06,1,
        GS07,1,
        GS08,1,
        GS09,1,
        GS10,1,
        GS11,1,
        GS12,1,
        GS13,1,
        GS14,1,
        GS15,1,
        }   

    OperationRegion(\GPSE, SystemIO, 0x0424, 0x2)	// Genernal Purpose SMI Enable
    Field(\GPSE, ByteAcc, NoLock, Preserve)	{
        GPS0,  	1,					// GPI0 SMI Enable
        GPS1,   1,					// GPI1 SMI Enable
        KBCE,   1,					// PS2 KB PME Enable
            ,   1,					
        EXTE,   1,					// EXT SMI Enable
        PME,    1,					// PCI PME Enable
            ,   2,
        RING,   1,					// Ring Wakeup
            ,   5,
        USBE,   1,					// USB Resume
            ,   1,
        } 
        
    OperationRegion(\Glos, SystemIO, 0x0428, 0x2)	// Global Status
    Field(\Glos, ByteAcc, NoLock, Preserve)	{
            , 6,					//
        SSMI, 1,					// software SMI
        PRII, 1,					// primary IRQ
            , 2,					//
        SLPE, 1, 					// sleep enable(Rx05)
        SIRS, 1,					// serirq status
            , 4,
        }
        
    OperationRegion(\WIRQ, SystemIO, 0x042a, 0x1)	// IRQ Resume Reg
    Field(\WIRQ, ByteAcc, NoLock, Preserve) {
        IRQR, 8,
        }
    
    OperationRegion(\Stus, SystemIO, 0x0430, 0x1)	// Global Status
    Field(\Stus, ByteAcc, NoLock, Preserve)	{
        PADS, 8,
        } 

	OperationRegion(\Prie, SystemIO, 0x0434, 0x1)
	Field(\Prie, ByteAcc, NoLock, Preserve) {
		    , 5,
		CMAE, 1,	// COMA_EN
		CMBE, 1,	// COMB_EN
	}
	
    //
    //  General Purpose Event
    //
    Scope(\_GPE)
    {
        Method(_L02) {
            Notify(\_SB.PCI0.VT86.PS2K, 0x02)	//Internal Keyboard PME Status
        }
        
        Method(_L04) {
            Notify(\_SB.SLPB, 0x80)
        }
        
        Method(_L05) {
            Notify(\_SB.PCI0,0x2)
        }

        Method(_L08) {
            Notify(\_SB.PCI0.VT86.EUR1, 0x2)
            Notify(\_SB.PCI0.VT86.EUR2, 0x2)            
        }
                       
        Method(_L09) {
            Notify(\_SB.PCI0.VT86.PS2M, 0x02)	//Internal Mouse Controller PME Status
        }
               
        Method(_L0D) {
            Notify(\_SB.PCI0.HDAC, 0x02)
        }

        Method(_L0E) {				//USB Wake up Status
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
        
        If (LEqual (Arg0, 1))       //S1
        {
            Notify (\_SB.SLPB, 0x02)
        }

        Or (Arg0, 0xA0,  Local0)
        Store (Local0, DBG1)    //80 Port: A1, A2, A3....

        IF (LEqual(Arg0, 0x01))	{   //S1
            And(IRQR,0x7F,IRQR)		//Disable IRQ Resume Reg, IRQR:Rx2A
            While(PRII){            //PRII:Rx28[7]
                Store (One, PRII)	//Clear Primary IRQ resume Status
            }
            While(LNotEqual(PADS, 0x00)){    //PADS: Rx30[1:7]
                Store (PADS, PADS)	//Clear Primary Activity Detect Status
            }
        }

        Notify(\_SB.SLPB, 0x2)

        IF (LEqual(Arg0, 0x03))	    //S3
        {
            Store(0x2,\_SB.PCI0.MEMC.FSEG)  //Set F Segment to Read only
		}

        Or (Arg0, 0xB0,  Local0)
        Store (Local0, DBG1)    //80 Port: B1, B2, B3....
        Return (0)
    }

    //
    // System sleep down
    //
    Method (_PTS, 1, NotSerialized)
    {

        Or (Arg0, 0xF0,  Local0)
        Store (Local0, DBG1)    //80 Port: F1, F2, F3....

        IF (LEqual(Arg0, 0x01))	{       // S1
            While(PRII)
            {
                Store (One, PRII)	//Clear Primary IRQ resume Status
            }
            While(LNotEqual(PADS, 0x00))
            {
                Store (PADS, PADS)	//Clear Primary Activity Detect Status
            }
            Or(IRQR,0x80,IRQR)		//Enable IRQ Resume Reg

        } //End of Arg0 EQ 0x01

        IF (LEqual(Arg0, 0x03)) {       //S3
             Store(0x0,\_SB.PCI0.MEMC.FSEG)     //Disable F Segment Read/Write
        } 

        IF (LEqual(Arg0, 0x04)) {       //S4
         }

        IF (LEqual(Arg0, 0x05)) {       //S5
            Store (Zero, GS04)          // Clear EXTSMI# Status, why?
         }
        sleep(0x64)
        Return (0x00)
    }


    Method(STRC, 2) {   // Compare two String
        If(LNotEqual(Sizeof(Arg0), Sizeof(Arg1))) {
            Return(1)
        }
        
        Add(Sizeof(Arg0), 1, Local0)
        
        Name(BUF0, Buffer(Local0) {})
        Name(BUF1, Buffer(Local0) {})
        
        Store(Arg0, BUF0)
        Store(Arg1, BUF1)
        
        While(Local0) {
            Decrement(Local0)
            If(LNotEqual(Derefof(Index(BUF0, Local0)), Derefof(Index(BUF1, Local0)))) {
                Return(1)
            }
        }
        Return(0)		// Str1 & Str2 are match
    }


    //
    //  System Bus
    //
    Scope(\_SB)
    {

        // define Sleeping button as mentioned in ACPI spec 2.0
        Device (SLPB)
        {
            Name (_HID, EISAID("PNP0C0E"))	// Hardware Device ID SLEEPBTN
            Method(_STA, 0) {
                Return(0x0B)	// non-present, enabled, functioning
            }
    
            Name(_PRW, Package(2){0x04,5})  //Internal Keyboard Controller PME Status; S5
        }

Device(PCI0)
{
    Name(_HID,EISAID ("PNP0A08"))    // Indicates PCI Express host bridge hierarchy
    Name(_CID,EISAID ("PNP0A03"))    // For legacy OS that doesn't understand the new HID

    Name(_ADR,0x00000000)            // Device (HI WORD)=0, Func (LO WORD)=0
    
    
    Name (_BBN,0)

    Method(_INI, 0)
    {
    }
    
    Name (_S3D, 3)

    Method(_STA, 0) {
        Return(0x0F)	// present, enabled, functioning
    }
    
    Name(_PRW, Package(2){0x5,0x4})     // PME#

    Method(_CRS,0) {
        Name(BUF0,ResourceTemplate() {
            WORDBusNumber(		// Bus 0
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

            IO(			        // IO Resource for PCI Bus
                Decode16,
                0x0CF8,
                0x0CF8,
                1,
                8
            )

            WORDIO(			    // IO from 0x0000 - 0x0cf7
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

            WORDIO(			    // IO from 0x0d00 - 0xffff
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
    	    Return(0x0F)	// present, enabled, functioning
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
            }Else {
                If(LEqual(\_SB.PCI0.USBD.CMDR, 0x00)) {
                    Return(0x0D)
                }Else{
                    Return(0x0F)	// present, enabled, functioning
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
            }Else {
                If(LEqual(\_SB.PCI0.SDIO.CMDR, 0x00)) {
                    Return(0x0D)
                }Else{
                    Return(0x0F)	// present, enabled, functioning
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
            }Else {
                If(LEqual(\_SB.PCI0.SDMS.CMDR, 0x00)) {
                    Return(0x0D)
                }Else{
                    Return(0x0F)	// present, enabled, functioning
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
            }Else {
                If(LEqual(\_SB.PCI0.CENF.CMDR, 0x00)) {
                    Return(0x0D)
                }Else{
                    Return(0x0F)	// present, enabled, functioning
                }
            }
        }
    }
    
Device(IDEC)
{

    Name(_ADR, 0x000F0000)	//D15F0: a Pata device
    
    Method(_STA,0,NotSerialized)	//Status of the Pata Device
    {
        If(LNot(LEqual(\_SB.PCI0.IDEC.VID,0x1106)))
        {
            Return(0x00)	//device not exists
        }
        Else
        {
            If(LEqual(\_SB.PCI0.IDEC.CMDR,0x00))
            {
                Return(0x0D)	//device exists & disable
            }
            Else
            {
                Return(0x0F)	//device exists & enable
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
        EPCH, 1,			// Enable Primary channel.        
        Offset(0x4A),
        PSPT, 8,			// IDE Timings, Primary Slave
        PMPT, 8,			// IDE Timings, Primary Master         
        Offset(0x52),
        PSUT, 4,			// Primary Slave UDMA Timing
        PSCT, 1,			// Primary Drive Slave Cabal Type
        PSUE, 3,			// Primary Slave UDMA Enable
        PMUT, 4,			// Primary Master UDMA Timing
        PMCT, 1,			// Primary Drive Master Cabal Type
        PMUE, 3,			// Primary Master UDMA Enable        
    }

    Name(REGF,0x01)		//accessible OpRegion default
    Method(_REG,2,NotSerialized)	// is PCI Config space accessible as OpRegion?
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
    {         	        	// Primary / Secondary channels timings
        Package(){120, 180, 240, 383, 600},	        // Timings in ns - Mode 4,3,2,1,0 defined from ATA spec.
        Package(){0x20, 0x22, 0x33, 0x47, 0x5D },	// PIO Timing - Mode 4,3,2,1,0
        Package(){4, 3, 2, 1, 0},		           	// PIO mode (TIM0,0)
        Package(){2, 1, 0, 0},		            	// Multi-word DMA mode
        Package(){120, 80, 60, 45, 30, 20, 15},	    // Min UDMA Timings in ns
        Package(){6,5,4,4,3,3,2,2,1,1,1,1,1,1,0},   // UDMA mode 	
        Package(){0x0E, 8, 6, 4, 2, 1, 0},	        // UDMA timing   
    })    
    
    Name(TMD0,Buffer(0x14){})
    CreateDwordField(TMD0,0x00,PIO0)
    CreateDwordField(TMD0,0x04,DMA0)
    CreateDwordField(TMD0,0x08,PIO1)
    CreateDwordField(TMD0,0x0C,DMA1)
    CreateDwordField(TMD0,0x10,CHNF)
    
    Name(GMPT, 0)		// Master PIO Timings
    Name(GMUE, 0)		// Master UDMA enable
    Name(GMUT, 0)		// Master UDMA Timings
    Name(GSPT, 0)		// Slave PIO Timings
    Name(GSUE, 0)		// Slave UDMA enable
    Name(GSUT, 0)		// Slave UDMA Timings
       
    Device(CHN0)	//Primary Channel: Pata device
    {
        Name(_ADR,0x00)
        
        Method(_STA,0,NotSerialized)
        {
            If(LNotEqual(\_SB.PCI0.IDEC.EPCH, 0x1)) 
            {
                Return(0x00)	//channel disable
            }                         
            Else 
            {
                Return(0x0F)	//channel enable
            }
       }
        Method(_GTM,0,NotSerialized)	//Get Timing Mode
        {
            Return(GTM(PMPT,PMUE,PMUT,PSPT,PSUE,PSUT))
        }
        Method(_STM, 3)			// Set Timing PIO/DMA Mode
       {			
           Store(Arg0, TMD0)	// Copy Arg0 into TMD0 buffer
           Store(PMPT, GMPT)	// Master PIO Timings
           Store(PMUE, GMUE)	// Master UDMA enable
           Store(PMUT, GMUT)	// Master UDMA Timings
           Store(PSPT, GSPT)	// Slave PIO Timings
           Store(PSUE, GSUE)	// Slave UDMA enable
           Store(PSUT, GSUT)	// Slave UDMA Timings
           STM()
           Store(GMPT, PMPT)	// Master PIO Timings
           Store(GMUE, PMUE)	// Master UDMA enable
           Store(GMUT, PMUT)	// Master UDMA Timings
           Store(GSPT, PSPT)	// Slave PIO Timings
           Store(GSUE, PSUE)	// Slave UDMA enable
           Store(GSUT, PSUT)	// Slave UDMA Timings
       }				// end Method _STM
			                                                
        Device(DRV0)	//Master Device
        {
            Name(_ADR,0x00)	//0 indicates master drive
            Method(_GTF,0,NotSerialized)	//Get Task File: return a buffer of ATA command used to re-initialize the device
            {
            	Return(GTF(0,PMUE,PMUT,PMPT))
            }
        }
        Device(DRV1)	//Slave Device
        {
            Name(_ADR,0x01)	//1 indicates slave drive
            Method(_GTF,0,NotSerialized)	//Get Task File: return a buffer of ATA command used to re-initialize the device
            {
            	Return(GTF(0,PSUE,PSUT,PSPT))
            }
        }
    }

    Method(GTM,6,Serialized)
    {
        Store(Ones,PIO0)	//default value: all bits set to 1
        Store(Ones,PIO1)	//default value: all bits set to 1
        Store(Ones,DMA0)	//default value: all bits set to 1
        Store(Ones,DMA1)	//default value: all bits set to 1
        Store(0x10,CHNF)	//default value: 0x10
        If(REGF)
        {
        }
        Else
        {
            Return(TMD0)	//unable to setup PCI config space as opRegion;return default value
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
        Return(TMD0)	//return timing mode
    }
    

    Method(STM, 0, Serialized)
    {
            
        If(REGF){}				// PCI space not accessible
        Else	{  Return(TMD0)  }
                               
        Store(0x00, GMUE)	    	// Master UDMA Disable  
        Store(0x00, GSUE)	    	// Slave UDMA Disable  
        Store(0x07, GMUT)			// Master UDMA Mode 0 
        Store(0x07, GSUT)			// Slave UDMA Mode 0 
                    
        If(And(CHNF, 0x1))
        {     		
            Store(Match(DeRefOf(Index(TIM0, 4)), MLE, DMA0, MTR,0,0), Local0)    // Get DMA mode
            Store(DeRefOf(Index(DeReFof(Index(TIM0, 6)), Local0)), GMUT)         // Timing bit mask 66Mhz
            Or(GMUE, 0x07, GMUE)			                                // Enable UltraDMA for Device 0
        }				
        Else	// non - UDMA mode. Possible Multi word DMA
        {	    			
            If(Or(LEqual(PIO0,Ones), LEqual(PIO0,0)))
            {      	
                If(And(LLess(DMA0,Ones), LGreater(DMA0,0)))
                {
                    Store(DMA0, PIO0)		// Make PIO0=DMA0
                }	  	
            }
        }
            		                
        If(And(CHNF, 0x4))
        {
            Store(Match(DeRefOf(Index(TIM0, 4)), MLE, DMA1, MTR,0,0), Local0)
            Store(DeRefOf(Index(DeReFof(Index(TIM0, 6)), Local0)), GSUT) // Timing bit mask 66Mhz
            Or(GSUE, 0x07, GSUE)			                        // Enable UltraDMA for Device 0
        } 
        Else	// non - UDMA mode. Possible Multi word DMA
        {
            If(Or(LEqual(PIO1, Ones), LEqual(PIO1,0)))
            {	      		
                If(And(LLess(DMA1, Ones), LGreater(DMA1,0)))
                {
                   Store(DMA1, PIO1)		// Make PIO1 = DMA1
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
        CreateByteField(Local1, 1, Mode)		// PIO mode
        CreateByteField(Local2, 1, UMOD)		// Ultra mode
        CreateByteField(Local1, 5, PCHA)		// master or slave
        CreateByteField(Local2, 5, UCHA)		// master or slave
        And(Arg0,0x03,Local3)			

        If(Lequal(And(Local3,0x01),0x01)) 
        {
            Store(0xB0,PCHA)			// drive 1
            Store(0xB0,UCHA)			// drive 1
        }			

        If(Arg1)
        {   		 
            Store(DeRefOf(Index(DeReFof(Index(TIM0, 5)), Arg2)), UMOD)     //Programming DMA Mode	
            Or( UMOD, 0x40, UMOD) 
        }		   									
        Else 
        {	// non-UltraDMA							   
            Store(Match(DeRefOf(Index(TIM0, 1)), MEQ, Arg3, MTR,0,0), Local0)
            Or(0x20, DeRefOf(Index(DeReFof(Index(TIM0, 3)), Local0)), UMOD)
        }

        Store(Match(DeRefOf(Index(TIM0, 1)), MEQ, Arg3, MTR,0,0), Local0)
        Or(0x08, DeRefOf(Index(DeReFof(Index(TIM0, 2)), Local0)), Mode)
        Concatenate(Local1, Local2, Local6)
        Return(Local6)		
                                                                                                                
    } // end of GTF	   		
}

//----------------------------------------------------------------
//
//	Copyright (c) 2005-2012 VIA Technologies, Inc.
//	This program contains proprietary and confidential information.
//	All rights reserved except as may be permitted by prior written
//	consent.
//
//----------------------------------------------------------------
//Rev	Date	 	Name	Description
//----------------------------------------------------------------

Device(USB1)	{
    Name(_ADR,0x00100000) 	//Address+function.

    Name(_PRW, Package(2){0x0E,3})
    
    Name(_S3D, 3)

    OperationRegion(U2F0,PCI_Config,0x00,0xC2)
    Field(U2F0,ByteAcc,NoLock,Preserve){
            Offset(0x00),
            VID, 16,
            Offset(0x04),
            CMDR, 3,
            Offset(0x3c),
            U3IR, 4,			//USB1 Interrupt Line
            Offset(0x84),
            ECDX, 2				//USB1 PM capability status register
    }

    Method(_STA,0) {			//Status of the USB1 Device
        If(LEqual(\_SB.PCI0.USB1.CMDR, 0x00)) {
            Return(0x0D)
        } Else {
            Return(0x0F)
        }
    }
}

Device(USB2)	{
    Name(_ADR,0x00100001) 	//Address+function.
    
    Name(_PRW, Package(2){0x0E,3})

    Name(_S3D, 3)

    OperationRegion(U2F1,PCI_Config,0x00,0xC2)
    Field(U2F1,ByteAcc,NoLock,Preserve){
            Offset(0x00),
            VID, 16,
            Offset(0x04),
            CMDR, 3,
            Offset(0x3c),
            U4IR, 4,			//USB2 Interrupt Line
            Offset(0x84),
            ECDX, 2				//USB2 PM capability status register
    }

    Method(_STA,0) {			//Status of the USB2 Device
        If(LEqual(\_SB.PCI0.USB2.CMDR, 0x00)) {
            Return(0x0D)
        } Else {
            Return(0x0F)
        }
    }
}

Device(USB3){
    Name(_ADR,0x00100002) 	//Address+function.
    
    Name(_PRW, Package(2){0x0E,3})
    
    Name(_S3D, 3)

    OperationRegion(U2F2,PCI_Config,0x00,0xC2)
    Field(U2F2,ByteAcc,NoLock,Preserve){
        Offset(0x00),
        VID, 16,
        Offset(0x04),
        CMDR, 3,
        Offset(0x3c),
        U5IR, 4,			//USB3 Interrupt Line
        Offset(0x84),
        ECDX, 2				//USB3 PM capability status register
    }

        Method(_STA,0) {			//Status of the USB3 Device
            If(LEqual(\_SB.PCI0.USB3.CMDR, 0x00)) {
                Return(0x0D)
            } Else {
                Return(0x0F)
            }
        }
}


Device(EHCI)	{
    Name(_ADR,0x00100004) 	//Address+function.
    
    Name(_PRW, Package(2){0x0E,3})
    
    Name(_S3D, 3)
    
    OperationRegion(U2F4,PCI_Config,0x00,0xC2)
    Field(U2F4,ByteAcc,NoLock,Preserve){
        Offset(0x00),
        VID, 16,
        Offset(0x04),
        CMDR, 3,
        Offset(0x3c),
        U7IR, 4,			//EHCI1 Interrupt Line
        Offset(0x84),
        ECDX, 2				//EHCI1 PM capability status register
    }

    Method(_STA,0) {			//Status of the EHCI1 Device
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
                Method (_STA, 0)
                {
                    Return (0x0F)
                }
				Name (PXXE, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite,
                        0xE0000000,         
                        0x10000000,         
                        )
                })
                Method (_CRS, 0)
                {
                    
                    Return (PXXE)
                }
            }           

//----------------------------------------------------------------
//
//	Copyright (c) 2005-2012 VIA Technologies, Inc.
//	This program contains proprietary and confidential information.
//	All rights reserved except as may be permitted by prior written
//	consent.
//
//----------------------------------------------------------------
//Rev	Date	 	Name	Description
//----------------------------------------------------------------





Device(VT86) {
        Name(_ADR,0x00110000) 	//Address+function.


        OperationRegion(VTSB, PCI_Config, 0x00, 0x100)
        Field(\_SB.PCI0.VT86.VTSB,ByteAcc,NoLock,Preserve) {
            Offset(0x2),
            DEID, 16,	// Device ID
            Offset(0x2C),
            ID2C,8,		// RX2C
            ID2D,8,		// RX2D
            ID2E,8,		// RX2E
            ID2F,8,		// RX2F
            Offset(0x44),
            PIRE, 4,
            PIRF, 4,
            PIRG, 4,            
            PIRH, 4,	// PIRQH# Routing
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
            ESB2, 1,	// RX5002 USB3					
            EIDE, 1,    // RX5003 EIDE	
            EUSB, 1,	// RX5004 USB1	
            ESB1, 1,	// RX5005 USB2
            USBD, 1,	// RX5006 USB Device Mode controller
            Offset(0x51),
            EKBC, 1,	// RX5100 Internal Keyboard controller
            KBCC, 1,	// RX5101 Internal KBC Configuration
            EPS2, 1,	// RX5102 Internal PS2 Mouse
            ERTC, 1,	// RX5103 Internal RTC
            SDIO, 1,    // RX5104 enable SDIO controller
                , 2,
            Offset(0x55),
                , 4,
            PIRA, 4, 	// PCI IRQA
            PIRB, 4, 	// PCI IRQB
            PIRC, 4,    // PCI IRQC
                , 4,
            PIRD, 4, 	// PCI IRQD
            
            Offset(0x58),
                , 6,
            ESIA, 1,    // Enable Source Bridge IO APIC
                , 1,

            Offset(0x81),   // Enable ACPI I/O
                , 7,
            ENIO, 1,
            Offset(0x88),   
                , 7,
            IOBA, 9,        //Power Management I/O Base
                        
            Offset(0x94),
                , 5,
            PLLD, 1,	// RX9405 Internal PLL Reset During Suspend 0:Enable,1:Disable    
            
            Offset(0xB0),	
                , 4,
            EU1E, 1,	//Embedded COM1
            EU2E, 1,	//Embedded COM2
                , 2,
            Offset(0xB2),	                
            UIQ1, 4,	// UART1 IRQ
            UIQ2, 4,	// UART2 IRQ		
            Offset(0xB4),						
            U1BA, 7,	// UART1 I/O base address.	
                , 1,
            U2BA, 7,	// UART2 I/O base address.	
                , 1,
            Offset(0xB7),					
                , 3,
            UDFE, 1,   // UART DMA Funtion Enable
            Offset(0xB8),	
                , 2,
            DIBA, 14,   // UART DMA I/O Base Address
    		
            Offset(0xBC),
            SPIB, 24,           
            Offset(0xD0),
                , 4,
            SMBA, 12,   //SMBus I/O Base (16-byte I/O space)
            Offset(0xD2),
            ENSM, 1,    //Enable SMBus IO 
                , 7,
            Offset(0xF6),
            REBD,   8,              //Internal Revision ID
    }
        
    Device(APCM)    // APIC MMIO
    {
        Name(_HID, EISAID("PNP0C02"))	// Hardware Device ID, Motherboard Resources
        Name(_UID, 0x1100)
        
        Name(CRS, ResourceTemplate()
        {
            Memory32Fixed(ReadWrite, 0xFEE00000, 0x00001000, LAPM)  // Local APIC MMIO Space
            Memory32Fixed(ReadWrite, 0x00000000, 0x00000000, SIAM)  // Sourth Bridge IO APIC MMIO Space
        })
        
        Method(_CRS, 0)
        {
            CreateDWordField(CRS, ^SIAM._BAS, BAS1)
            CreateDWordField(CRS, ^SIAM._LEN, LEN1)
            
            
            If(LEqual(\_SB.PCI0.VT86.ESIA, 1))
            {
                Store(0xFEC00000, BAS1)
                Store(0x1000, LEN1)
            }            

            Return(CRS)
        }

    }

	
//----------------------------------------------------------------
//
//	Copyright (c) 2005-2012 VIA Technologies, Inc.
//	This program contains proprietary and confidential information.
//	All rights reserved except as may be permitted by prior written
//	consent.
//
//----------------------------------------------------------------
//Rev	Date	 	Name	Description
//----------------------------------------------------------------







//----------------------------------------------------------------
//
//	Copyright (c) 2005-2012 VIA Technologies, Inc.
//	This program contains proprietary and confidential information.
//	All rights reserved except as may be permitted by prior written
//	consent.
//
//----------------------------------------------------------------
//Rev	Date	 	Name	Description
//----------------------------------------------------------------


Device(PS2M) 				//PS2 Mouse Device
{
    Name(_HID,EISAID("PNP0F13"))	// Hardware Device ID
    
    Method(_STA,0)		 	//Status of the PS2 Mouse device
    {
        Return(0x0F)
    }
            
    Method(_CRS,0)	
    {				// Current Resource
        Name (BUF1, ResourceTemplate ()
        {
            IRQNoFlags ()
            {12}
        })
        Return(BUF1)
    }
    
    Name(_PRW, Package(){0x09, 0x04})
}

Device(PS2K) 				// PS2 Keyboard Device
{				
        Name(_HID,EISAID("PNP0303"))	// Hardware Device ID
        Name(_CID,EISAID("PNP030B"))	// PNP030B is Microsoft reserved
        
        Method(_STA,0)	 		//Status of the PS2 Keyboard device
        {
            Return(0x0F)
        }
        
        Name (_CRS, ResourceTemplate ()
        {
            IO (Decode16,
                0x0060,             // Address Range Minimum
                0x0060,             // Address Range Maximum
                0x01,               // Address Alignment
                0x01,               // Address Length
                )
            IO (Decode16,
                0x0064,             // Address Range Minimum
                0x0064,             // Address Range Maximum
                0x01,               // Address Alignment
                0x01,               // Address Length
                )
            IRQNoFlags ()
                {1}
        })
        Name(_PRW, Package(){0x02, 0x04})
}   


Device(DMAC)
{
    Name(_HID, EISAID("PNP0200")) 
    
    Name(_CRS,ResourceTemplate() {
       IO(Decode16, 0x0, 0x0, 0, 0x10)      // Master DMA Controller
       IO(Decode16, 0x81, 0x81, 0, 0x3)     // DMA Page Registers
       IO(Decode16, 0x87, 0x87, 0, 0x1)
       IO(Decode16, 0x89, 0x89, 0, 0x3)
       IO(Decode16, 0x8F, 0x8F, 0, 0x1)
       IO(Decode16, 0xC0, 0xC0, 0, 0x20)     // Slave DMA Controller
        DMA(Compatibility,NotBusMaster,Transfer8) {4}   // Channel 4 is used to cascade the two DMA controller.
    })
}

Device(RTC)
{
    Name(_HID,EISAID("PNP0B00"))
    
    Name(BUF0,ResourceTemplate()
    {
      IO(Decode16, 0x70, 0x70, 0x00, 0x02)
      IO(Decode16, 0x74, 0x74, 0x00, 0x00, AAAA)  
      IRQNoFlags() {8}      // Active High, Edge Sensitive, Non-sharable
    })

    Method(_CRS,0,Serialized)
    {
        CreateByteField(BUF0, ^AAAA._LEN, LEN1)
        If(LEqual(\_SB.PCI0.VT86.EP74, 0x01)) 
        {
            Store(0x02, LEN1)
        }
        Return(BUF0)
    }
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
    
    Name(BUF0, ResourceTemplate()
    {
      IO(Decode16,0x40,0x40,0x00,0x04)
      IRQNoFlags() {0}
    })

    Method(_CRS, 0, Serialized)
    {
        Return(BUF0)
    }   
}

Device(SPKR)    // System Speaker
{
    Name(_HID,EISAID("PNP0800"))

    Name(_CRS,ResourceTemplate() {
        IO(Decode16,0x61,0x61,0x01,0x01)
    })
}




    
//----------------------------------------------------------------
//
//	Copyright (c) 2005-2012 VIA Technologies, Inc.
//	This program contains proprietary and confidential information.
//	All rights reserved except as may be permitted by prior written
//	consent.
//
//----------------------------------------------------------------
//Rev	Date	 	Name	Description
//----------------------------------------------------------------






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
Alias(PRSA, PRSB)
Alias(PRSA, PRSC)
Alias(PRSA, PRSD)
Alias(PRSA, PRSE)
Alias(PRSA, PRSF)
Alias(PRSA, PRSG)
Alias(PRSA, PRSH)

Device(LNKA)	{
    Name(_HID, EISAID("PNP0C0F")) 	// PCI interrupt link
    Name(_UID, 1)
    Method(_STA, 0)
    {
        If(LEqual(\_SB.PCI0.VT86.PIRA, 0x00)) 
        {
            Return(0x09)	//disabled
        }Else {
            Return(0x0B)  	//enabled, but no UI
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
        CreateWordField (Arg0, 1, IRA)  //Byte 1 and Byte 2 in the IRQ Descriptor Definition
        FindSetRightBit (IRA, Local0)
        Decrement (Local0)
        Store (Local0, \_SB.PCI0.VT86.PIRA)
    }
}


Device(LNKB)	{
    Name(_HID, EISAID("PNP0C0F")) 	// PCI interrupt link
    Name(_UID, 2)
    Method(_STA, 0)
    {
        If(LEqual(\_SB.PCI0.VT86.PIRB, 0x00)) 
        {
            Return(0x09)	//disabled
        }Else {
            Return(0x0B)  	//enabled, but no UI
        }
    }
    
    Method(_PRS) 
    {
        Return(PRSB)
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
        CreateWordField (Arg0, 1, IRA)  //Byte 1 and Byte 2 in the IRQ Descriptor Definition
        FindSetRightBit (IRA, Local0)
        Decrement (Local0)
        Store (Local0, \_SB.PCI0.VT86.PIRB)
    }
}


Device(LNKC)	{
    Name(_HID, EISAID("PNP0C0F")) 	// PCI interrupt link
    Name(_UID, 3)
    Method(_STA, 0)
    {
        If(LEqual(\_SB.PCI0.VT86.PIRC, 0x00)) 
        {
            Return(0x09)	//disabled
        }Else {
            Return(0x0B)  	//enabled, but no UI
        }
    }
    
    Method(_PRS) 
    {
        Return(PRSC)
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

Device(LNKD)	{
    Name(_HID, EISAID("PNP0C0F")) 	// PCI interrupt link
    Name(_UID, 4)
    Method(_STA, 0)
    {
        If(LEqual(\_SB.PCI0.VT86.PIRD, 0x00)) 
        {
            Return(0x09)	//disabled
        }Else {
            Return(0x0B)  	//enabled, but no UI
        }
    }
    
    Method(_PRS) 
    {
        Return(PRSD)
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
Device(LNKE)	{
    Name(_HID, EISAID("PNP0C0F")) 	// PCI interrupt link
    Name(_UID, 5)
    Method(_STA, 0)
    {
        If(LEqual(\_SB.PCI0.VT86.PIRE, 0x00)) 
        {
            Return(0x09)	//disabled
        }Else {
            Return(0x0B)  	//enabled, but no UI
        }
    }
    
    Method(_PRS) 
    {
        Return(PRSE)
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
Device(LNKF)	{
    Name(_HID, EISAID("PNP0C0F")) 	// PCI interrupt link
    Name(_UID, 6)
    Method(_STA, 0)
    {
        If(LEqual(\_SB.PCI0.VT86.PIRF, 0x00)) 
        {
            Return(0x09)	//disabled
        }Else {
            Return(0x0B)  	//enabled, but no UI
        }
    }
    
    Method(_PRS) 
    {
        Return(PRSF)
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
Device(LNK0)	{
    Name(_HID, EISAID("PNP0C0F")) 	// PCI interrupt link
    Name(_UID, 7)
    Method(_STA, 0)
    {
        If(LEqual(\_SB.PCI0.VT86.PIRG, 0x00)) 
        {
            Return(0x09)	//disabled
        }Else {
            Return(0x0B)  	//enabled, but no UI
        }
    }
    
    Method(_PRS) 
    {
        Return(PRSG)
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
Device(LNK1)
{
    Name(_HID, EISAID("PNP0C0F")) 	// PCI interrupt link
    Name(_UID, 8)
    Method(_STA, 0)
    {
        If(LEqual(\_SB.PCI0.VT86.PIRH, 0x00)) 
        {
            Return(0x09)	//disabled
        }Else {
            Return(0x0B)  	//enabled, but no UI
        }
    }
    
    Method(_PRS) 
    {
        Return(PRSH)
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

//
// Embedded UART1
//
Device(EUR1)								// Communication Device (Modem Port)
{			
	Name(_HID, EISAID("PNP0501"))			// PnP Device ID 16550 Type
	Name(_UID, 0x1) 			   
	
	Name(_PRW, Package(){8, 4})

	Method(_PSW, 1) 
	{
		Store(0x20, PADS)		// clear _STS first //PMIO Rx30[5]
		And(IRQR,0xFE,IRQR) 	// don not issue SMI //PMIO Rx2A[0]
				
		If (Arg0) 
		{
			Store(One, CMAE)
		} 
		Else 
		{
			Store(Zero, CMAE)
		}
	}

	Method(_STA)					// Status of the COM device
	{				
		Store(0x00, Local0)

		If(LNotEqual(\_SB.PCI0.VT86.ECOM, Zero))
		{
			If(\_SB.PCI0.VT86.EU1E)
			{
				Store(0x0F, Local0) 
			}
			Else
			{							// if base address is not equal to zero.		
				If(LNotEqual(\_SB.PCI0.VT86.U1BA, Zero))	  
				{ 
					Store(0x0D, Local0) 
				}
			}	 
		}
		Return(Local0)
	}

	Method(_DIS,0)								
	{ 
	  Store(Zero, \_SB.PCI0.VT86.EU1E)		// disable embedded COM A.
	} 

	Name(RSRC,ResourceTemplate (){
		IO(Decode16,0x0,0x0,0x08,0x08)
		IRQNoFlags() {}
	})

	Method(_CRS, 0) 					   
	{		
		And(_STA(), 0x04, Local0)			// If the device is disabled, return the blank template.
		If(LEqual(Local0,Zero)) 			//
		{									//	  
			Return(RSRC)					//
		}									//
												
		Name(BUF1,ResourceTemplate() {		// This is the buffer prepared for OS.
			IO(Decode16,0x3F8,0x3F8,0x08,0x08)
			IO(Decode16,0x4080,0x4080,0x02,0x02)			
			IRQNoFlags(){4}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x00}	// DMA 0 
		})
		
		CreateByteField(BUF1, 0x02, IOLO)	// IO Port MIN Low
		CreateByteField(BUF1, 0x03, IOHI)	// IO Port MIN High
		CreateByteField(BUF1, 0x04, IORL)	// IO Port MAX Low
		CreateByteField(BUF1, 0x05, IORH)	// IO Port MAX High

		if(LNotEqual(\_SB.PCI0.VT86.UDFE, 0x00))  // if enable DMA
		{
			CreateByteField(BUF1, 0x0A, DILO)	// DMA IO Port MIN Low
			CreateByteField(BUF1, 0x0B, DIHI)	// DMA IO Port MIN High		
			CreateByteField(BUF1, 0x0C, DIRL)	// DMA IO Port MAX Low
			CreateByteField(BUF1, 0x0D, DIRH)	// DMA IO Port MAX High	
		}

		CreateWordField(BUF1, 0x11, IRQV)	// IRQ mask
		
		ShiftLeft(\_SB.PCI0.VT86.U1BA, 0x03, local0)	// IO low.	AD7~AD0 														
		ShiftRight(\_SB.PCI0.VT86.U1BA, 0x05, local1)	// IO high. AD9~AD8 	 
		
		Store(local0, IOLO)
		Store(local1, IOHI)
		Store(local0, IORL)
		Store(local1, IORH)
		
		Store(0x00, IRQV)					 // reset IRQ resource.
		If(LNotEqual(\_SB.PCI0.VT86.UIQ1, 0x00))   
		{									 // put assigned IRQ to return buffer if there is any.						 
			ShiftLeft(One, \_SB.PCI0.VT86.UIQ1, IRQV)
		}											

		if(LNotEqual(\_SB.PCI0.VT86.UDFE, 0x00))  // if enable DMA
		{
			ShiftLeft(\_SB.PCI0.VT86.DIBA, 0x02, local0)	// IO low.	AD7~AD0 
			ShiftRight(\_SB.PCI0.VT86.DIBA, 0x06, local1)	// IO high. AD16~AD8 	 
		
			Store(local0, DILO)
			Store(local1, DIHI)
			Store(local0, DIRL)
			Store(local1, DIRH)
		}
		Return(BUF1)				
		
	} // _CRS

	Name(_PRS,ResourceTemplate() 
	{
		StartDependentFn(0,0)
		{
			IO(Decode16,0x3F8,0x3F8,0x1,0x8)
			IO(Decode16,0x4080,0x4080,0x02,0x02)							
			IRQ(Edge,ActiveHigh,Exclusive) {0x4}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x00}	// DMA 0 			
		}
		StartDependentFnNoPri()
		{
			IO(Decode16,0x2F8,0x2F8,0x1,0x8)
			IO(Decode16,0x4080,0x4080,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x3}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x00}	// DMA 0 			
		}
		StartDependentFnNoPri()
		{
			IO(Decode16,0x3E8,0x3E8,0x1,0x8)
			IO(Decode16,0x4080,0x4080,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x4}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x00}	// DMA 0 			
		}
		StartDependentFnNoPri()
		{
			IO(Decode16,0x2E8,0x2E8,0x1,0x8)
			IO(Decode16,0x4080,0x4080,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x3}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x00}	// DMA 0 			
		}
		StartDependentFn(2,2)
		{
			IO(Decode16,0x3F8,0x3F8,0x1,0x8)
			IO(Decode16,0x4080,0x4080,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x3}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x00}	// DMA 0 			
		}
		StartDependentFn(2,2)
		{
			IO(Decode16,0x2F8,0x2F8,0x1,0x8)
			IO(Decode16,0x4080,0x4080,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x4}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x00}	// DMA 0 			
		}
		StartDependentFn(2,2)
		{
			IO(Decode16,0x3E8,0x3E8,0x1,0x8)
			IO(Decode16,0x4080,0x4080,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x3}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x00}	// DMA 0 			
		}
		StartDependentFn(2,2)
		{
			IO(Decode16,0x2E8,0x2E8,0x1,0x8)
			IO(Decode16,0x4080,0x4080,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x4}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x00}	// DMA 0 			
		}
		EndDependentFn()
	})// _PRS

	Method(_SRS, 1) 
	{				
		//
		// The Arg0 format is the same as _PRS, and _CRS.
		//												  
		CreateByteField (Arg0, 0x02, IOLO)		// IO Port Low
		CreateByteField (Arg0, 0x03, IOHI)		// IO Port High
		if(LNotEqual(\_SB.PCI0.VT86.UDFE, 0x00))  // if enable DMA
		{
			CreateByteField (Arg0, 0x0A, DILO)		// DMA IO Port Low
			CreateByteField (Arg0, 0x0B, DIHI)		// DMA IO Port High		
		}
		CreateWordField (Arg0, 0x11, IRQW)		// IRQ

		Store(One, \_SB.PCI0.VT86.EU1E) 		// enable embedded COM A.

		ShiftRight(IOLO, 0x03, local0)			// set embedded COM A IO base.
		ShiftLeft(IOHI, 0x05, local1)			//
		Or(local0, local1, \_SB.PCI0.VT86.U1BA)//

		if(LNotEqual(\_SB.PCI0.VT86.UDFE, 0x00))  // if enable DMA
		{
			ShiftRight(DILO, 0x02, local0)			// set embedded COM A DMA IO base.
			ShiftLeft(DIHI, 0x06, local1)			//
			Or(local0, local1, \_SB.PCI0.VT86.DIBA) //
		}
		
		FindSetLeftBit(IRQW, Local0)			// set embedded COM A IRQ.
		If(LNotEqual(Local0, Zero)) 			//
		{										//		  
			Subtract(Local0, 0x01, Local0)		// IRQ is in a bit-mask fashion.	
		}										//	  
												//		   
		Store(Local0, \_SB.PCI0.VT86.UIQ1)

	}// _SRS

}// embedded UART1.

//
// Embedded UART2
//
Device(EUR2)								// Communication Device (Modem Port)
{			
	Name(_HID, EISAID("PNP0501"))			// PnP Device ID 16550 Type
	Name(_UID, 0x2) 			   
	
	Name(_PRW, Package(){8, 4})

	Method(_PSW, 1) 
	{
		Store(0x40, PADS)		// clear _STS first //PMIO Rx30[6]
		And(IRQR,0xFE,IRQR) 	// don not issue SMI //PMIO Rx2A[0]I 
		
		If (Arg0) 
		{
			Store(One, CMBE)
		} 
		Else 
		{
			Store(Zero, CMBE)
		}
	}

	//
	// An empty resource.
	//
	Name(RSRC,ResourceTemplate (){
		IO(Decode16,0x0,0x0,0x08,0x08)
		IRQNoFlags() {}
	})

	Method(_STA)							// Status of the COM device
	{				
		Store(0x00, Local0)

		If(LNotEqual(\_SB.PCI0.VT86.ECOM, Zero))
		{
			If(\_SB.PCI0.VT86.EU2E)
			{
				Store(0x0F, Local0) 
			}
			Else
			{									// if base address is not equal to zero.		
				If(LNotEqual(\_SB.PCI0.VT86.U2BA, Zero))	  
				{ 
					Store(0x0D, Local0) 
				}			
			}	 
		}	
		Return(Local0)
	}

	Method(_DIS,0)								
	{ 
	  Store(Zero, \_SB.PCI0.VT86.EU2E)		// disable embedded COM B.
	} 

	Method(_CRS, 0) 					   
	{		
		And(_STA(), 0x04, Local0)			// If the device is disabled, return the blank template.
		If(LEqual(Local0,Zero)) 			//
		{									//	  
			Return(RSRC)					//
		}									//
												
		Name(BUF1,ResourceTemplate() {		// This is the buffer prepared for OS.
			IO(Decode16,0x2F8,0x2F8,0x08,0x08)
			IO(Decode16,0x4082,0x4082,0x02,0x02)											
			IRQNoFlags(){3}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x03}	//			
		})
		
		CreateByteField(BUF1, 0x02, IOLO)	// IO Port MIN Low
		CreateByteField(BUF1, 0x03, IOHI)	// IO Port MIN High
		CreateByteField(BUF1, 0x04, IORL)	// IO Port MAX Low
		CreateByteField(BUF1, 0x05, IORH)	// IO Port MAX High

		if(LNotEqual(\_SB.PCI0.VT86.UDFE, 0x00))  // if enable DMA
		{
			CreateByteField(BUF1, 0x0A, DILO)	// DMA IO Port MIN Low
			CreateByteField(BUF1, 0x0B, DIHI)	// DMA IO Port MIN High		
			CreateByteField(BUF1, 0x0C, DIRL)	// DMA IO Port MAX Low
			CreateByteField(BUF1, 0x0D, DIRH)	// DMA IO Port MAX High	
		}
		CreateWordField(BUF1, 0x11, IRQV)	// IRQ mask			
											 	   
		ShiftLeft(\_SB.PCI0.VT86.U2BA, 0x03, local0)	// IO low.	AD7~AD0												
		ShiftRight(\_SB.PCI0.VT86.U2BA, 0x05, local1)	// IO high. AD9~AD8 	 
		
		Store(local0, IOLO)
		Store(local1, IOHI)
		Store(local0, IORL)
		Store(local1, IORH)
		
		Store(0x00, IRQV)					 // reset IRQ resource.
		If(LNotEqual(\_SB.PCI0.VT86.UIQ2, 0x00))   
		{									 // put assigned IRQ to return buffer if there is any.						 
			ShiftLeft(One, \_SB.PCI0.VT86.UIQ2, IRQV)
		}											

		if(LNotEqual(\_SB.PCI0.VT86.UDFE, 0x00))  // if enable DMA
		{
			ShiftLeft(\_SB.PCI0.VT86.DIBA, 0x02, local0)	// IO low.	AD7~AD0 
			ShiftRight(\_SB.PCI0.VT86.DIBA, 0x06, local1)	// IO high. AD16~AD8 	 
		
			Store(local0, DILO)
			Store(local1, DIHI)
			Store(local0, DIRL)
			Store(local1, DIRH)
		}
		Return(BUF1)				
		
	} // _CRS

	Name(_PRS,ResourceTemplate() 
	{
		StartDependentFn(0,0)
		{
			IO(Decode16,0x3F8,0x3F8,0x1,0x8)
			IO(Decode16,0x4082,0x4082,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x4}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x03}	//			
		}
		StartDependentFnNoPri()
		{
			IO(Decode16,0x2F8,0x2F8,0x1,0x8)
			IO(Decode16,0x4082,0x4082,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x3}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x03}	//			
		}
		StartDependentFnNoPri()
		{
			IO(Decode16,0x3E8,0x3E8,0x1,0x8)
			IO(Decode16,0x4082,0x4082,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x4}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x03}	//		
		}
		StartDependentFnNoPri()
		{
			IO(Decode16,0x2E8,0x2E8,0x1,0x8)
			IO(Decode16,0x4082,0x4082,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x3}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x03}	//		
		}
		StartDependentFn(2,2)
		{
			IO(Decode16,0x3F8,0x3F8,0x1,0x8)
			IO(Decode16,0x4082,0x4082,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x3}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x03}	//			
		}
		StartDependentFn(2,2)
		{
			IO(Decode16,0x2F8,0x2F8,0x1,0x8)
			IO(Decode16,0x4082,0x4082,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x4}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x03}	//
		}
		StartDependentFn(2,2)
		{
			IO(Decode16,0x3E8,0x3E8,0x1,0x8)
			IO(Decode16,0x4082,0x4082,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x3}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x03}	//			
		}
		StartDependentFn(2,2)
		{
			IO(Decode16,0x2E8,0x2E8,0x1,0x8)
			IO(Decode16,0x4082,0x4082,0x02,0x02)											
			IRQ(Edge,ActiveHigh,Exclusive) {0x4}
			DMA(Compatibility, NotBusMaster, Transfer8, ) {0x03}	//		
		}
		EndDependentFn()
	})// _PRS

	Method(_SRS, 1) 
	{				
		//
		// The Arg0 format is the same as _PRS, and _CRS.
		//												  
		CreateByteField (Arg0, 0x02, IOLO)		// IO Port Low
		CreateByteField (Arg0, 0x03, IOHI)		// IO Port High
		if(LNotEqual(\_SB.PCI0.VT86.UDFE, 0x00))  // if enable DMA
		{
			CreateByteField (Arg0, 0x0A, DILO)		// DMA IO Port Low
			CreateByteField (Arg0, 0x0B, DIHI)		// DMA IO Port High		
		}
		CreateWordField (Arg0, 0x11, IRQW)		// IRQ

		Store(One, \_SB.PCI0.VT86.EU2E) 		// enable embedded COM A.

		ShiftRight(IOLO, 0x03, local0)			// set embedded COM A IO base.
		ShiftLeft(IOHI, 0x05, local1)			//
		Or(local0, local1, \_SB.PCI0.VT86.U2BA) //

		if(LNotEqual(\_SB.PCI0.VT86.UDFE, 0x00))  // if enable DMA
		{	
			ShiftRight(DILO, 0x02, local0)			// set embedded COM A DMA IO base.
			ShiftLeft(DIHI, 0x06, local1)			//
			Or(local0, local1, \_SB.PCI0.VT86.DIBA) //
		}
		FindSetLeftBit(IRQW, Local0)			// set embedded COM A IRQ.
		If(LNotEqual(Local0, Zero)) 			//
		{										//		  
			Subtract(Local0, 0x01, Local0)		// IRQ is in a bit-mask fashion.	
		}										//	  
												//		   
		Store(Local0, \_SB.PCI0.VT86.UIQ2)		  

	}// _SRS

}// embedded UART2.



	
	Device(RMSC)    // all "PNP0C02" devices- pieces that don't fit anywhere else
    {
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
        
        Method(_CRS, 0){
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


} // End of VT86


    
//----------------------------------------------------------------
//
//	Copyright (c) 2005-2012 VIA Technologies, Inc.
//	This program contains proprietary and confidential information.
//	All rights reserved except as may be permitted by prior written
//	consent.
//
//----------------------------------------------------------------
//Rev	Date	 	Name	Description
//----------------------------------------------------------------

Name(PICM, Package(){		
    
    // VIA VGA Device(Integrated Graphics Device)
    Package(){0x0001ffff, 0, \_SB.PCI0.VT86.LNKA, 0}, 	// VGA, INTA
     
    //PCI Slot 1
    Package(){0x0008ffff, 0, \_SB.PCI0.VT86.LNKA, 0}, 	// Slot 1, INTA
    Package(){0x0008ffff, 1, \_SB.PCI0.VT86.LNKA, 0}, 	// Slot 1, INTB
    Package(){0x0008ffff, 2, \_SB.PCI0.VT86.LNKA, 0}, 	// Slot 1, INTC
    Package(){0x0008ffff, 3, \_SB.PCI0.VT86.LNKA, 0}, 	// Slot 1, INTD

    //PCI Slot 2
    Package(){0x0009ffff, 0, \_SB.PCI0.VT86.LNKA, 0}, 	// Slot 2, INTA
    Package(){0x0009ffff, 1, \_SB.PCI0.VT86.LNKA, 0}, 	// Slot 2, INTB
    Package(){0x0009ffff, 2, \_SB.PCI0.VT86.LNKA, 0}, 	// Slot 2, INTC
    Package(){0x0009ffff, 3, \_SB.PCI0.VT86.LNKA, 0}, 	// Slot 2, INTD
    
    //PCI Slot 3
    Package(){0x000Affff, 0, \_SB.PCI0.VT86.LNKA, 0}, 	// Slot 3, INTA
    Package(){0x000Affff, 1, \_SB.PCI0.VT86.LNKA, 0}, 	// Slot 3, INTB
    Package(){0x000Affff, 2, \_SB.PCI0.VT86.LNKA, 0}, 	// Slot 3, INTC
    Package(){0x000Affff, 3, \_SB.PCI0.VT86.LNKA, 0}, 	// Slot 3, INTD
    
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
    Package(){0x0014ffff, 0, \_SB.PCI0.VT86.LNKA, 0},  	// HD Audio, INTA

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
    Package(){0x000fffff, 0, 0, 0x15}, 	//IDE, INTA
    
    // VIA UHCI USB1 Device
    Package(){0x0010ffff, 0, 0, 0x14},
    // VIA UHCI USB2 Device
    Package(){0x0010ffff, 1, 0, 0x16},
    // VIA UHCI USB3 Device
    Package(){0x0010ffff, 2, 0, 0x15},
    // VIA EHCI USB 2.0 Device
    Package(){0x0010ffff, 3, 0, 0x17},
       
    // SB HDAC(Azalia) Audio
    Package(){0x0014ffff, 0, 0, 0x11}, 	//HD Audio , INTA

}) // end of APIX

Method(_PRT, 0, NotSerialized)
{
    If(LNot(PICF))
    {
        //PIC
        Return(PICM) 
    }Else{
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
            }Else {
                If(LEqual(\_SB.PCI0.P2PB.CMDR, 0x00)) {
                    Return(0x0D)
                }Else{
                    Return(0x0F)	// present, enabled, functioning
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
            }Else {
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
            }Else {
                If(LEqual(\_SB.PCI0.HDAC.CMDR, 0x00)) {
                    Return(0x0D)
                }Else{
                    Return(0x0F)	// present, enabled, functioning
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

Procedure:	RMEM

Description:	System board extension Device node for ACPI BIOS
Place the device under \_SB scope, As per Msft the MEM
Device is used to reserve Resources that are decoded out of PCI Bus
Important consideration :
Logic to reserve the memory within 0xC0000 - 0xFFFFF Extended BIOS area is based on assumption, that
the BIOS Post has detected all expansion ROMs in the region and made their memory ranges
shadowable ( copied to RAM at the same address, for performance reasons). The rest of the region is left non-Shadowable,
hence no memory is decoded there. Such region is decoded to PCI bus (to be reserved in PCI0._CRS)
Whatever memory is Shadowed, thus, decoded as non "FF"s, is required to be reserved in "SYSM" System board extension Device node,
unless is not already reserved by some of PCI Device drivers. There have been observed the difference of how Win9x & Win2000
OSes deal with Expansion ROM memory. Win9x Device drivers are tend to claim its expension ROMs regions as used
by the device; Win2000 never use such ROM regions for its devices. Therefore there can be different
approach used for different OSes in reservation unclaimed memory in "SYSM" Device node.
is forwarded to PCI Bus

Input: Nothing

Output: _CRS buffer

**************************************************************************/

Device(RMEM) {
    Name(_HID, EISAID("PNP0C01"))	// Hardware Device ID, System Board

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
