////////////////////////////////////////////////////////////////////////////
//  File name : s34ml01g1.sv
////////////////////////////////////////////////////////////////////////////
//  Copyright (C) 2012 Free Model Foundry; http://www.FreeModelFoundry.com
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2 as
//  published by the Free Software Foundation.
//
//  MODIFICATION HISTORY:
//
//  version: |    author:   | mod date: | changes made:
//  V1.0        S.Petrovic   12 Sep 14   Initial Release
//  V1.1        S.Petrovic   12 Sep 24   Renamed Ready Busy output port and
//                                       corrected its initial value

////////////////////////////////////////////////////////////////////////////
//  PART DESCRIPTION:
//
//  Library:     FLASH
//  Technology:  FLASH MEMORY
//  Part:        s34ml01g1
//
//  Description: NAND interface family based on MirrorBit technology
//               Flash Memory
//
////////////////////////////////////////////////////////////////////////////
//  Known Bugs:
//
////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION                                                     //
////////////////////////////////////////////////////////////////////////////
`timescale 1 ns/1 ns

module s34ml01g1
 (
    IO7     ,
    IO6     ,
    IO5     ,
    IO4     ,
    IO3     ,
    IO2     ,
    IO1     ,
    IO0     ,

    CLE     ,
    ALE     ,
    CENeg   ,
    RENeg   ,
    WENeg   ,
    WPNeg   ,
    R
 );

////////////////////////////////////////////////////////////////////////
// Port / Part Pin Declarations
////////////////////////////////////////////////////////////////////////

    inout  IO7  ;
    inout  IO6  ;
    inout  IO5  ;
    inout  IO4  ;
    inout  IO3  ;
    inout  IO2  ;
    inout  IO1  ;
    inout  IO0  ;

    input  CLE     ;
    input  ALE     ;
    input  CENeg   ;
    input  RENeg   ;
    input  WENeg   ;
    input  WPNeg   ;
    output R       ;

// interconnect path delay signals

    wire  IO7_ipd  ;
    wire  IO6_ipd  ;
    wire  IO5_ipd  ;
    wire  IO4_ipd  ;
    wire  IO3_ipd  ;
    wire  IO2_ipd  ;
    wire  IO1_ipd  ;
    wire  IO0_ipd  ;

    wire [7 : 0] A;
    assign A = {IO7_ipd,
                IO6_ipd,
                IO5_ipd,
                IO4_ipd,
                IO3_ipd,
                IO2_ipd,
                IO1_ipd,
                IO0_ipd };

    wire [7 : 0 ] DIn;
    assign DIn = {IO7_ipd,
                  IO6_ipd,
                  IO5_ipd,
                  IO4_ipd,
                  IO3_ipd,
                  IO2_ipd,
                  IO1_ipd,
                  IO0_ipd };

    wire [7 : 0 ] DOut;
    assign DOut = {IO7,
                   IO6,
                   IO5,
                   IO4,
                   IO3,
                   IO2,
                   IO1,
                   IO0 };

    wire  CLE_ipd     ;
    wire  ALE_ipd     ;
    wire  CENeg_ipd   ;
    wire  RENeg_ipd   ;
    wire  WENeg_ipd   ;
    wire  WPNeg_ipd   ;

//  internal delays

    reg PROG_in         ;
    reg PROG_out        ;
    reg ERS_in          ;
    reg ERS_out         ;
    reg TR_in           ;
    reg TR_out          ;
    reg CBSYR_in        ;
    reg CBSYR_out       ;

    reg [7 : 0] DOut_zd;

    wire  IO7_zd   ;
    wire  IO6_zd   ;
    wire  IO5_zd   ;
    wire  IO4_zd   ;
    wire  IO3_zd   ;
    wire  IO2_zd   ;
    wire  IO1_zd   ;
    wire  IO0_zd   ;

    assign {IO7_zd,
            IO6_zd,
            IO5_zd,
            IO4_zd,
            IO3_zd,
            IO2_zd,
            IO1_zd,
            IO0_zd  } = DOut_zd;

    reg RY_zd = 1'b0;

    parameter mem_file_name   = "none";//"s34ml01g1.mem"
    parameter OTP_file_name   = "none";//"s34ml01g1_OTP.mem"
    parameter UserPreload     = 1'b0;
    parameter TimingModel     = "DefaultTimingModel";

    parameter PartID         = "s34ml01g1";
    parameter MaxData        = 8'hFF;
    parameter BlockNum       = 1023;
    parameter BlockSize      = 63;
    parameter PageNum        = 16'hFFFF;
    parameter PageNumInBl    = 64;
    parameter PageSize       = 2111;
    parameter SegmentNum     = 7;   // 7 segments within page
    parameter SegmentSize    = 512;
    parameter SperSegSize    = 16;
    parameter SpareSize      = 64;
    parameter MainSize       = 2048;
    parameter OTPPageNum     = 63;

    parameter MainAreaAddBit     = 11;
    parameter HAddBitPag         = 17;
    parameter HAddBitBl          = 27;
    parameter HAddBitSpareSeg    = 5;
    parameter HAddBitSeg         = 10;

    // If generic Long_Timming is set to 0, you need to uncomment line below

    //`define SPEEDSIM;
    // constraint memory preload file parameters
    parameter preload_line_width    = 160;
    parameter preload_address_width = 7;
    parameter preload_data_width    = 2;

    integer memory_read_data;

    // control signals
    reg ERS_ACT         =1'b0;
    reg PRG_ACT         =1'b0;
    reg RD_CACH_ACT     =1'b0;
    reg RD_CACH_LAST    =1'b0;
    reg RSTSTART        =1'b0;
    reg RSTDONE         =1'b0;
    //    Control signals for read operation
    reg STAT_ACT        =1'b0;

    reg PGR_ACT         =1'b0;   //  Page read in progress
    reg PGD_ACT         =1'b0;   //  Page Duplicate
    reg OTP_ACT         =1'b0;
     // powerup
    reg PoweredUp       =1'b0;
    reg reseted         =1'b0;
    reg flagWRITE       =1'b1;

    reg write           =1'b0;
    reg read            =1'b0;

    integer WER_01;

    // 8 bit Address
    integer AddrCom          ;
    // Address within page
    integer Address          ;      // 0 - Pagesize
    // Page Number
    integer PageAddr         = -1;  //-1 - PageNum

    // Block Number
    integer BlockAddr        = -1;  //-1 - BlockNum

     //Data
    integer Data             ;      //-1 - MaxData

    integer TmpPage;
    integer TmpSegm ;
    integer AddrWithinPage;
    integer PageWithinBlock;
    integer Segment;
    reg [23:0] RowAddr;
    reg [15:0] ColAddr;

    integer RdPage;
    integer RdAddr;
    integer RdSeg;
    integer RdBlck;

    integer WrSeg;

    integer ProgBlck;
    integer ProgPage;

    reg firstFlag = 1'b0;

    integer mem_data;

    //ID control signals
    integer IDAddr           ;      // 0 - 4

         // program control signals
    integer  CashBuffData[0:PageSize]; //Page chache register
    integer  CWrAddr          ;     // Cash -1  - Pagesize +1
    integer  CWrPage          ;     // Cash 0  - PageNum

    // Read Cache signals
    integer  CRdAddr          ;
    integer  CRdPage          ;
    integer  CPageWithinBlock ;
    reg FrstCachRd;

    integer WrBuffData[0:PageSize];
    integer WrAddr          ;     // -1  - Pagesize +1
    integer WrPage          ;     //  0  - PageNum
    reg [SegmentNum:0] SegForProg; //array [0:SegmentNum] of 0/1

    integer PDBuffer [0:PageSize];

    integer Page_pom;
    integer cnt_addr;

    integer  segment      ; //  RANGE -1 TO SegmentNum;
    integer  pom_seg      ; //  RANGE -1 TO SegmentNum;

    integer ssa[0:SegmentNum];  // has to be initialized
    integer sea[0:SegmentNum];  // has to be initialized

    integer OTP_Area[0:(PageSize+1)*(BlockSize+1)-1];

    reg [0:(PageNum+1)*(SegmentNum+1)-1] ProgramedFlag;
    reg [0:(OTPPageNum+1)*(SegmentNum+1)-1] OTPProgramedFlag;

    // ID Array
    integer IDArray[0:3];
    integer ONFIArray[0:3];
    integer PPageArray[0:767];
    reg Id_ONFI;

    // timing check violation
    reg Viol    = 1'b0;

    // initial
    integer i,j;

    integer WrBlck          ;
    integer ErsBlck         ;
    integer TmpBlck         ;

    //Functional
    reg[7:0] Status         = 8'hC0;
    reg oe = 1'b0;
    integer Page     ; // 0 - PageNum
    integer Blck     ; // 0 - BlockNum

    time erase_time;
    time page_prog_time;
    time prog_time;

    reg[7:0] TempData;

    event oe_event;

    // states
    reg [5:0] current_state;
    reg [5:0] next_state;

    reg WP_D;
    reg [SegmentNum:0] SegProgSt = 0;

    reg rising_edge_PoweredUp = 1'b0;
    reg rising_edge_reseted = 1'b0;
    reg rising_edge_RSTDONE = 1'b0;
    reg rising_edge_RSTSTART = 1'b0;
    reg falling_edge_write = 1'b0;
    reg rising_edge_TR_out = 1'b0;
    reg rising_edge_PROG_out = 1'b0;
    reg rising_edge_CBSYR_out = 1'b0;
    reg rising_edge_ERS_out = 1'b0;
    reg rising_edge_WENeg = 1'b0;
    reg falling_edge_WENeg = 1'b0;
    reg tADL_check = 1'b0;

    // FSM states
    parameter IDLE          =6'h00;
    parameter UNKNOWN       =6'h01;  //   wrong command sequneces
    parameter PREL_RD       =6'h02;
    parameter RESET         =6'h03;
    parameter A0_RD         =6'h04;
    parameter A1_RD         =6'h05;
    parameter A2_RD         =6'h06;
    parameter RD_WCMD       =6'h07;  //   waiting for the confirm read command
    parameter BUFF_TR       =6'h08;
    parameter RD            =6'h09;
    parameter CAC_PREL      =6'h0A;  //   Coloumn address change
    parameter A0_CAC        =6'h0B;
    parameter A1_CAC        =6'h0C;  //   Wait for confirm EO command
    parameter ID_PREL       =6'h0D;
    parameter ID            =6'h0E;
    parameter PREL_PRG      =6'h0F;
    parameter PGD_PREL      =6'h10;
    parameter A0_PRG        =6'h11;
    parameter A1_PRG        =6'h12;
    parameter A2_PRG        =6'h13;
    parameter DATA_PRG      =6'h14;
    parameter PGMS_CAC      =6'h15;
    parameter A0_PRG_CAC    =6'h16;
    parameter PGMS          =6'h17;
    parameter PREL_ERS      =6'h18;
    parameter A1_ERS        =6'h19;
    parameter A2_ERS        =6'h1A;
    parameter ERS_EXEC      =6'h1B;
    parameter A0_PGD        =6'h1C;
    parameter A1_PGD        =6'h1D;
    parameter A2_PGD        =6'h1E;
    parameter A3_PGD        =6'h1F;
    parameter PREL_OTP      =6'h20;
    parameter OTP_ENTR1     =6'h21;
    parameter OTP_ENTR2     =6'h22;
    parameter OTP           =6'h23;
    parameter RD_OTP        =6'h24;
    parameter CBSYR         =6'h25;
    parameter RD_CACH       =6'h26;
    parameter WFRD          =6'h27;
    parameter ID_PREL_PP    =6'h28;
    parameter ID_PP         =6'h29;
/////////////////////////////////////////////////////////////////////////////
//Interconnect Path Delay Section
/////////////////////////////////////////////////////////////////////////////

    buf   (IO7_ipd , IO7 );
    buf   (IO6_ipd , IO6 );
    buf   (IO5_ipd , IO5 );
    buf   (IO4_ipd , IO4 );
    buf   (IO3_ipd , IO3 );
    buf   (IO2_ipd , IO2 );
    buf   (IO1_ipd , IO1 );
    buf   (IO0_ipd , IO0 );

    buf   (CLE_ipd      , CLE      );
    buf   (ALE_ipd      , ALE      );
    buf   (CENeg_ipd    , CENeg    );
    buf   (RENeg_ipd    , RENeg    );
    buf   (WENeg_ipd    , WENeg    );
    buf   (WPNeg_ipd    , WPNeg    );

/////////////////////////////////////////////////////////////////////////////
// Propagation  delay Section
/////////////////////////////////////////////////////////////////////////////

    nmos   (IO7  ,   IO7_zd  , 1);
    nmos   (IO6  ,   IO6_zd  , 1);
    nmos   (IO5  ,   IO5_zd  , 1);
    nmos   (IO4  ,   IO4_zd  , 1);
    nmos   (IO3  ,   IO3_zd  , 1);
    nmos   (IO2  ,   IO2_zd  , 1);
    nmos   (IO1  ,   IO1_zd  , 1);
    nmos   (IO0  ,   IO0_zd  , 1);

    nmos   (R    ,   1'b0    , ~RY_zd);

    wire deg;

 // Needed for TimingChecks
 // VHDL CheckEnable Equivalent

    wire Check_IO0_WENeg;
    assign Check_IO0_WENeg    =  ~CENeg;

    wire Check_WENeg;
    assign Check_WENeg    =  PoweredUp;

    wire tADLCheck;
    assign tADLCheck = tADL_check;

    memory_features memory_features_i0();

specify

    // tipd delays: interconnect path delays , mapped to input port delays.
    // In Verilog is not necessary to declare any tipd_ delay variables,
    // they can be taken from SDF file
    // With all the other delays real delays would be taken from SDF file

    specparam       tpd_CENeg_IO0           =   1;//tcea, tchz
    specparam       tpd_RENeg_IO0           =   1;//trea, trhZ
    specparam       tpd_WENeg_R             =   1;//twb

    //tsetup values
    specparam       tsetup_IO0_WENeg        =   1;//tds
    specparam       tsetup_CLE_WENeg        =   1;//tcls
    specparam       tsetup_CENeg_WENeg      =   1;//tcs
    specparam       tsetup_ALE_WENeg        =   1;//tals
    specparam       tsetup_WENeg_RENeg      =   1;//twhr
    specparam       tsetup_RENeg_WENeg      =   1;//twhw
    specparam       tsetup_R_RENeg          =   1;//trr
    specparam       tsetup_WPNeg_WENeg      =   1;//tww
    specparam       tsetup_CLE_RENeg        =   1;//tAR, tCLR
    specparam       tsetup_CENeg_RENeg      =   1;//tCR

    //thold values
    specparam       thold_CLE_WENeg         =   1;//tclh
    specparam       thold_CENeg_WENeg       =   1;//tch
    specparam       thold_ALE_WENeg         =   1;//talh
    specparam       thold_IO0_WENeg         =   1;//tdh
    specparam       thold_IO0_CENeg         =   1;//tCOH
    specparam       thold_IO0_RENeg         =   1;//tRLOH
    specparam       thold_IO1_RENeg         =   1;//tRHOH

    //tpw values
    specparam       tpw_WENeg_negedge       =   1;//twp
    specparam       tpw_WENeg_posedge       =   1;//twh
    specparam       tpw_RENeg_negedge       =   1;//trp
    specparam       tpw_RENeg_posedge       =   1;//treh
    specparam       tperiod_WENeg           =   1;//twc
    specparam       tperiod_WENeg_tADLCheck =   1;//tadl
    specparam       tperiod_RENeg           =   1;//trc

    //tdevice values: values for internal delays
    `ifdef SPEEDSIM
        // Program Operation
        specparam       tdevice_PROG     =   70000;
        //Block Erase Operation
        specparam       tdevice_BERS     =   300000 ;
        //Read Cache Busy Time
        specparam       tdevice_CBSYR    =   25000;
        //Page transfer time
        specparam       tdevice_TR       =   25000;

    `else // not SPEEDSIM
                // Program Operation
        specparam       tdevice_PROG     =   700000;
        //Block Erase Operation
        specparam       tdevice_BERS     =   3000000;
        //Read Cache Busy Time
        specparam       tdevice_CBSYR    =   25000;
        //Page transfer time
        specparam       tdevice_TR       =   25000;

    `endif // SPEEDSIM

///////////////////////////////////////////////////////////////////////////////
// Input Port  Delays  don't require Verilog description
///////////////////////////////////////////////////////////////////////////////
// Path delays                                                               //
///////////////////////////////////////////////////////////////////////////////

// specify transport delay for Data output paths

// Data ouptut paths
    ( CENeg => IO0 ) = tpd_CENeg_IO0;
    ( CENeg => IO1 ) = tpd_CENeg_IO0;
    ( CENeg => IO2 ) = tpd_CENeg_IO0;
    ( CENeg => IO3 ) = tpd_CENeg_IO0;
    ( CENeg => IO4 ) = tpd_CENeg_IO0;
    ( CENeg => IO5 ) = tpd_CENeg_IO0;
    ( CENeg => IO6 ) = tpd_CENeg_IO0;
    ( CENeg => IO7 ) = tpd_CENeg_IO0;

    ( RENeg => IO0 ) = tpd_RENeg_IO0;
    ( RENeg => IO1 ) = tpd_RENeg_IO0;
    ( RENeg => IO2 ) = tpd_RENeg_IO0;
    ( RENeg => IO3 ) = tpd_RENeg_IO0;
    ( RENeg => IO4 ) = tpd_RENeg_IO0;
    ( RENeg => IO5 ) = tpd_RENeg_IO0;
    ( RENeg => IO6 ) = tpd_RENeg_IO0;
    ( RENeg => IO7 ) = tpd_RENeg_IO0;

// R output path
    (WENeg => R) = tpd_WENeg_R;
///////////////////////////////////////////////////////////////////////////////
// Timing Violation                                                           /
///////////////////////////////////////////////////////////////////////////////
`ifndef __ICARUS__
    $setup ( IO0  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO1  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO2  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO3  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO4  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO5  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO6  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);
    $setup ( IO7  ,posedge WENeg &&& Check_IO0_WENeg ,tsetup_IO0_WENeg,Viol);

    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO0  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO1  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO2  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO3  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO4  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO5  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO6  ,thold_IO0_WENeg, Viol);
    $hold ( posedge WENeg &&& Check_IO0_WENeg , IO7  ,thold_IO0_WENeg, Viol);

    $setup ( CLE ,posedge WENeg &&& Check_IO0_WENeg, tsetup_CLE_WENeg, Viol);
    $setup ( ALE ,posedge WENeg &&& Check_IO0_WENeg, tsetup_ALE_WENeg, Viol);
    $setup ( CENeg  ,posedge WENeg,                  tsetup_CENeg_WENeg, Viol);
    $setup ( posedge WENeg  ,negedge RENeg,        tsetup_WENeg_RENeg , Viol);
    $setup ( posedge RENeg  ,negedge WENeg,        tsetup_RENeg_WENeg , Viol);
    $setup ( posedge R      ,negedge RENeg,        tsetup_R_RENeg    , Viol);
    $setup ( WPNeg          ,posedge WENeg,        tsetup_WPNeg_WENeg , Viol);
    $setup ( negedge CLE    ,negedge RENeg,        tsetup_CLE_RENeg   , Viol);
    $setup ( negedge ALE    ,negedge RENeg,        tsetup_CLE_RENeg   , Viol);
    $setup ( negedge CENeg  ,negedge RENeg,        tsetup_CENeg_RENeg , Viol);

    $hold  ( posedge WENeg &&& Check_WENeg,CLE,thold_CLE_WENeg, Viol);
    $hold  ( posedge WENeg &&& Check_WENeg,ALE,thold_ALE_WENeg, Viol);
    $hold  ( posedge WENeg &&& Check_WENeg,CENeg,thold_CENeg_WENeg,Viol);
    $hold  ( posedge CENeg,  IO0 &&& deg,       thold_IO0_CENeg,  Viol);
    $hold  ( posedge RENeg,  IO0 &&& deg,       thold_IO0_RENeg,  Viol);
    $hold  ( negedge RENeg,  IO1 &&& deg,       thold_IO1_RENeg,  Viol);

    $width (posedge WENeg                         , tpw_WENeg_posedge);
    $width (negedge WENeg                         , tpw_WENeg_negedge);
    $width (posedge RENeg                         , tpw_RENeg_posedge);
    $width (negedge RENeg                         , tpw_RENeg_negedge);
    $period(posedge WENeg                         , tperiod_WENeg);
    $period(negedge WENeg                         , tperiod_WENeg);
    $period(negedge RENeg                         , tperiod_RENeg);
    $period(posedge RENeg                         , tperiod_RENeg);
    $period(posedge WENeg &&&  tADLCheck          , tperiod_WENeg_tADLCheck);
`endif
    endspecify

         //Used as wait periods
    `ifdef SPEEDSIM
        time       poweredupT      = 100000; // 100 us
        time       RstErsT         = 5000;// 5 us
        time       RstProgT        = 10000; // 10 us
        time       RstReadT        = 5000;  // 5 us
    `else // not SPEEDSIM
        time       poweredupT      = 100000; // 100 us
        time       RstErsT         = 500000;// 500 us
        time       RstProgT        = 10000; // 10 us
        time       RstReadT        = 5000;  // 5 us
    `endif // SPEEDSIM

////////////////////////////////////////////////////////////////////////////////
// Main Behavior Block                                                        //
////////////////////////////////////////////////////////////////////////////////

 reg deq;
    //////////////////////////////////////////////////////////
    //          Output Data Gen
    //////////////////////////////////////////////////////////

    always @(DIn, DOut)
    begin
        if (DIn==DOut)
            deq=1'b1;
        else
            deq=1'b0;
    end
    // check when data is generated from model to avoid setuphold check in
    // those occasion
    assign deg=deq;

    // initialize memory and load preoload files if any
    // preload dedicated declarations
    reg [preload_line_width*8 : 1] scanf_str;
    reg [8:1] fetch_char;
    integer preload_iter;
    integer preload_file;
    integer scanf_address;
    integer scanf_data;

    initial
      begin: InitMemory
        integer i,j,k;

        memory_features_i0.initialize_w();

        for (i=0;i<= OTPPageNum;i=i+1)
          begin
            for (j=0;j<= PageSize;j=j+1)
            begin
              OTP_Area[i*(PageSize+1)+j]=MaxData;
            end
          end
        //page segment start address offset
        ssa[0]          =12'h000;
        ssa[1]          =12'h200;
        ssa[2]          =12'h400;
        ssa[3]          =12'h600;
        ssa[4]          =12'h800;
        ssa[5]          =12'h810;
        ssa[6]          =12'h820;
        ssa[7]          =12'h830;
        //page segment end address offset
        sea[0]          =12'h1FF;
        sea[1]          =12'h3FF;
        sea[2]          =12'h5FF;
        sea[3]          =12'h7FF;
        sea[4]          =12'h80F;
        sea[5]          =12'h81F;
        sea[6]          =12'h82F;
        sea[7]          =12'h83F;
        if (UserPreload && !(mem_file_name == "none"))
          begin
        // s34ml01g1 memory preload file
        //   /         - comment
        //   @aaaaaaa  - <aaaaaaa> stands for page address and address within
        //               first 2112 bytes of a page
        //               7FFFFFFF - max value !
        //   dd         - <dd> is Byte to be written at Mem(page)(offset++)
        //               page is <aaaaaaa> div 2112
        //               offset is <aaaaaaa> mod 2112
        //               offset is incremented on every write
            for (i=0;i<(PageNum+1)*(SegmentNum+1);i=i+1)
                ProgramedFlag[i] = 1'b0;
            for (i=0;i<(OTPPageNum+1)*(SegmentNum+1);i=i+1)
                OTPProgramedFlag[i] = 1'b0;
            scanf_address = 0;
            preload_file = $fopen(mem_file_name, "r");
            while($fgets(scanf_str, preload_file))
              begin
                fetch_char = scanf_str
                    [preload_line_width*8 : preload_line_width*8 - 7];
                while (!fetch_char)
                begin
                    scanf_str = scanf_str << 8;
                    fetch_char = scanf_str
                        [preload_line_width * 8 : preload_line_width * 8 - 7];
                end

                if ((fetch_char == "/") || (fetch_char == "\n"))
                begin
                    // empty lines and comments not processed
                end
                else
                begin
                    if (fetch_char == "@")
                    begin
                        scanf_address = 0;
                        for(preload_iter = 0;
                            preload_iter < preload_address_width;
                                preload_iter = preload_iter + 1)
                        begin
                            scanf_str = scanf_str << 8;
                            fetch_char = scanf_str[
                                preload_line_width * 8 :
                                preload_line_width * 8 - 7
                                ];
                            scanf_address = scanf_address * 16;
                            if ((fetch_char >= "0")&&(fetch_char <= "9"))
                                 scanf_address =
                                     scanf_address + (fetch_char - "0");
                            else if ((fetch_char >= "A")&&(fetch_char <= "F"))
                                 scanf_address =
                                     scanf_address + (fetch_char - "A") + 10;
                            else if ((fetch_char >= "a")&&(fetch_char <= "f"))
                                 scanf_address =
                                     scanf_address + (fetch_char - "a") + 10;
                        end
                    end
                    else
                    begin
                        scanf_data = 0;
                        for(preload_iter = 0;
                            preload_iter < preload_data_width;
                                preload_iter = preload_iter + 1)
                        begin
                            scanf_data = scanf_data * 16;
                            if ((fetch_char >= "0") && (fetch_char <= "9"))
                                 scanf_data = scanf_data + (fetch_char - "0");
                            else if ((fetch_char >= "A")&&(fetch_char <= "F"))
                                 scanf_data =
                                     scanf_data + (fetch_char - "A") + 10;
                            else if ((fetch_char >= "a")&&(fetch_char <= "f"))
                                 scanf_data =
                                     scanf_data + (fetch_char - "a") + 10;
                            scanf_str = scanf_str << 8;
                            fetch_char = scanf_str[
                                preload_line_width * 8 :
                                preload_line_width * 8-7
                                ];
                        end
                        if (scanf_address < ((PageNum + 1) *
                            (PageSize + 1)))
                          begin
                            memory_features_i0.write_mem_w
                                (scanf_address, scanf_data);
                            ProgramedFlag[scanf_address / SegmentSize]
                                                                    = 1'b1;
                          end
                        else
                            $display("Memory address out of range.");
                        scanf_address = scanf_address + 1;
                    end
                end
              end
          end
        if (UserPreload && !(OTP_file_name == "none"))
          begin
            $readmemh(OTP_file_name, OTP_Area);
            for (i=0;i<= OTPPageNum;i=i+1)
              begin
                for (j=0;j<= PageSize;j=j+1)
                  begin
                    if (OTP_Area[i*(PageSize+1)+j]!==MaxData)
                      begin
                        getSegment(j,segment);
                        OTPProgramedFlag[i*(SegmentNum+1)+segment] = 1'b1;
                        j = sea[segment]; // jump to segment end addr.
                      end
                  end
              end
          end
      end

    initial
    begin
        ERS_ACT         =1'b0;
        PRG_ACT         =1'b0;
        RSTSTART        =1'b0;
        RSTDONE         =1'b0;

        write           =1'b0;
        read            =1'b0;

        for(j=0;j<=PageSize;j=j+1)
          begin
              WrBuffData[j] = -1;
          end
        for(j=0;j<=SegmentNum;j=j+1)
          begin
              SegForProg[i]=1'b0;
          end
        WrAddr       = -1;
        WrPage      = -1;

        current_state  = IDLE;
        next_state     = IDLE;

        Status         = 8'b01100100;

        PROG_in   = 1'b0;
        PROG_out  = 1'b0;
        TR_in     = 1'b0;
        TR_out    = 1'b0;
        CBSYR_in  = 1'b0;
        CBSYR_out = 1'b0;

        firstFlag = 1'b0;
        flagWRITE   =1'b1;

    end

     //Power Up time 100 us;
    initial
    begin
        PoweredUp = 1'b0;
        #poweredupT  PoweredUp = 1'b1;
    end

    ////////////////////////////////////////////////////////////////////////////
    // process for reset control and FSM state transition
    ////////////////////////////////////////////////////////////////////////////
    always @(rising_edge_PoweredUp or next_state)
    begin
        if (rising_edge_PoweredUp)
          begin
            reseted <= 1'b1;
            current_state <= RD;
            RdPage = 0;
            RdBlck = 0;
            RdAddr = 0;
            page_prog_time = tdevice_PROG + WER_01;
            erase_time = tdevice_BERS + WER_01;
          end
        else if (PoweredUp)
          begin
            current_state <= next_state;
          end
        else
          begin
            current_state <= IDLE;
            reseted       <= 1'b0;
          end
    end

    wire gWE_n ;
    wire gCE_n ;
    wire gRE_n ;

// Glitches of less than 5ns on WE#,CE# and RE# do not afferct bus operations
    assign #5 gWE_n = WENeg_ipd;
    assign #5 gCE_n = CENeg_ipd;
    assign #5 gRE_n = RENeg_ipd;

    always @(WENeg)
    begin: PulseWatch1
        if (gWE_n == WENeg) $display("Glitch on WE#");
    end
    always @(CENeg)
    begin: PulseWatch
        if (gCE_n == CENeg) $display("Glitch on CE#");
    end
    always @(RENeg)
    begin: PulseWatch3
        if (gRE_n == RENeg) $display("Glitch on RE#");
    end

    //////////////////////////////////////////////////////////////////////////
    //process for generating the write and read signals
    //////////////////////////////////////////////////////////////////////////
    always @ (gWE_n, gCE_n, gRE_n)
    begin
        if (~gWE_n && ~gCE_n && gRE_n)
            write  =  1'b1;
        else if (gWE_n &&  ~gCE_n && gRE_n)
            write  =  1'b0;
        else
            write = 1'b0;

        if (gWE_n &&  ~gCE_n && ~gRE_n )
            read = 1'b1;
        else if (gWE_n &&  ~gCE_n && gRE_n )
            read = 1'b0;
        else
            read = 1'b0;
    end

     //////////////////////////////////////////////////////////////////////////
    //Latches 8 bit address on rising edge of WE#
    //Latches data on rising edge of WE#
    //////////////////////////////////////////////////////////////////////////
    always @ (posedge gWE_n)
    begin
        // latch 8 bit read address
        if (gWE_n && ALE && ~gCE_n && ~CLE && gRE_n)
            AddrCom = A[7:0];
        // latch data
        if (gWE_n && ~ALE && ~gCE_n && gRE_n)
            Data   =  DIn[7:0];
    end

    ////////////////////////////////////////////////////////////////////////////
    // Timing control for the Reset Operation
    ////////////////////////////////////////////////////////////////////////////
    time duration_rst;
    always @(rising_edge_RSTSTART or rising_edge_reseted)
    begin
        if (rising_edge_reseted)
            RSTDONE <= 1'b1; // reset done
        else if (reseted)
          begin
            if (rising_edge_RSTSTART && RSTDONE)
              begin
                if (ERS_ACT)
                    duration_rst = RstErsT;
                else if (PRG_ACT)
                    duration_rst = RstProgT;
                else
                    duration_rst = RstReadT;
                RSTDONE <= 1'b0;
                RSTDONE <= #duration_rst 1'b1;
              end
          end
    end

    ////////////////////////////////////////////////////////////////////////////
    // Main Behavior Process
    // combinational process for next state generation
    ////////////////////////////////////////////////////////////////////////////

    //WRITE CYCLE TRANSITIONS
    always @(falling_edge_write or rising_edge_reseted or
            rising_edge_TR_out or rising_edge_PROG_out or
            RSTDONE or rising_edge_ERS_out or rising_edge_CBSYR_out or WP_D)
    begin
        if (reseted != 1'b1 )
            next_state <= current_state;
        else if (rising_edge_reseted)
            next_state <= RD;
        else
            case (current_state)
            IDLE :
              begin
                if (falling_edge_write)
                  begin
                    if (CLE && !ALE && (Data==16'h00))
                        next_state <= PREL_RD;
                    else if (CLE && !ALE && (Data==16'h90))
                        next_state <= ID_PREL;
                    else if (CLE && !ALE && (Data==16'hEC))
                        next_state <= ID_PREL_PP;
                    else if (CLE && !ALE && (Data==16'h80) && WPNeg)
                        next_state <= PREL_PRG;
                    else if (CLE && !ALE && (Data==16'h60) && WPNeg)
                        next_state <= PREL_ERS;
                    else if (CLE && !ALE && (Data==16'h70))
                        next_state <= IDLE;
                    else if (CLE && !ALE && (Data==16'h29))
                        next_state <= PREL_OTP;
                    else
                        next_state <= IDLE;
                  end
              end

            UNKNOWN:
              begin
                if (falling_edge_write && CLE && !ALE && (Data==16'hFF))
                    next_state <= RESET;
              end

            RESET:
              begin
                if (RSTDONE)
                    next_state <= IDLE;
              end

            PREL_RD:
              begin
                if (falling_edge_write)
                  begin
                    if (ALE)
                        next_state <= A0_RD;
                    else
                      begin
                        if (OTP_ACT)
                            next_state <= OTP;
                        else
                            next_state <= IDLE;
                      end
                  end
              end

            A0_RD:
              begin
                if (falling_edge_write)
                  begin
                    if (ALE)
                        next_state <= A1_RD;
                    else
                      begin
                        if (OTP_ACT)
                            next_state <= OTP;
                        else
                            next_state <= IDLE;
                      end
                  end
              end

            A1_RD:
              begin
                if (falling_edge_write)
                  begin
                    if ((ALE && OTP_ACT && (AddrCom[7:6]== 2'b00)) ||
                                                 (ALE && !OTP_ACT))
                        next_state <= A2_RD;
                    else
                      begin
                        if (OTP_ACT)
                            next_state <= OTP;
                        else
                            next_state <= IDLE;
                      end
                  end
              end

            A2_RD:
              begin
                if (falling_edge_write)
                  begin
                    if ((ALE && OTP_ACT && (AddrCom == 8'h00)) ||
                                                 (ALE && !OTP_ACT))
                        next_state <= RD_WCMD;
                    else
                      begin
                        if (OTP_ACT)
                            next_state <= OTP;
                        else
                            next_state <= IDLE;
                      end
                  end
              end

            RD_WCMD:
              begin
                if (falling_edge_write)
                  begin
                    if (CLE && !ALE && ((Data == 16'h30) ||
                    (Data == 16'h35)))
                        next_state <= BUFF_TR;
                    else if (CLE)
                      begin
                        if (OTP_ACT)
                            next_state <= OTP;
                        else
                            next_state <= IDLE;
                      end
                  end
              end

            BUFF_TR:
              begin
                if (rising_edge_TR_out)
                  begin
                    if (OTP_ACT && !PGD_ACT)
                        next_state <= RD_OTP;
                    else
                        next_state <= RD;
                  end
              end

            RD:
              begin
                if (falling_edge_write)
                  begin
                    if (CLE && !ALE && (Data == 16'h00))
                      begin
                        if (STAT_ACT)
                            next_state <= RD;
                        else
                            next_state <= PREL_RD;
                      end

                    else if (CLE && !ALE && (Data == 16'h80) && !PGD_ACT
                    && WPNeg)
                        next_state <= PREL_PRG;
                    else if (CLE && !ALE && (Data==16'h90)
                     && !PGD_ACT)
                        next_state <= ID_PREL;
                    else if (CLE && !ALE && (Data==16'hEC)
                     && !PGD_ACT)
                        next_state <= ID_PREL_PP;
                    else if (CLE && !ALE && (Data == 16'h70))
                        next_state <= RD;
                    else if (CLE && (Data == 16'h60) && !ALE && !PGD_ACT
                    && WPNeg)
                        next_state <= PREL_ERS;
                    else if (CLE && !ALE && (Data == 16'h85) && PGD_ACT)
                        next_state <= PGD_PREL;
                    else if (CLE && !ALE && (Data == 16'h05) && !PGD_ACT)
                        next_state <= CAC_PREL;
                    else if (CLE && !ALE && (Data==8'h29) && !PGD_ACT)
                        next_state <= PREL_OTP;
                   else if (CLE && !ALE && (Data==8'h31) &&
                   !RD_CACH_ACT && !PGD_ACT)
                        next_state <= CBSYR;
                   else
                       next_state <= IDLE;
                end
              end

            RD_OTP:
              begin
                if (falling_edge_write)
                  begin
                    if (CLE && !ALE && (Data == 16'h00))
                      begin
                        if (STAT_ACT)
                            next_state <= RD_OTP;
                        else
                            next_state <= PREL_RD;
                      end
                    else if (CLE && !ALE && (Data == 16'h80) && WPNeg )
                        next_state <= PREL_PRG;
                    else if (CLE && !ALE && (Data == 16'h05) )
                        next_state <= CAC_PREL;
                    else if (CLE && !ALE && (Data == 16'h70))
                        next_state <= RD_OTP;
                    else
                        next_state <= OTP;
                  end
              end

            CBSYR:
              begin
                if (rising_edge_CBSYR_out)
                  begin
                    if (RD_CACH_LAST)
                        next_state <= RD;
                    else
                        next_state <= RD_CACH;
                  end
              end

            RD_CACH:
              begin
               if (falling_edge_write)
                  begin
                    if (CLE && !ALE && ((Data == 16'h31) || (Data == 16'h3F)))
                      begin
                        if ( TR_in == 1'b1)
                            next_state <= WFRD;// Waiting for read done
                        else
                            next_state <= CBSYR;
                      end
                    else if (CLE && !ALE && (Data == 16'h05))
                        next_state <= CAC_PREL;
                  end
              end

            WFRD:
              begin
                if (rising_edge_TR_out)
                    next_state <= CBSYR;
              end

            CAC_PREL:
              begin
                if (falling_edge_write)
                  begin
                    if (ALE)
                        next_state <= A0_CAC;
                    else
                      begin
                        if (OTP_ACT)
                            next_state <= OTP;
                        else
                            next_state <= IDLE;
                      end
                  end
              end

            A0_CAC:
              begin
                if (falling_edge_write)
                  begin
                    if (ALE)
                        next_state <= A1_CAC;
                    else
                      begin
                        if (OTP_ACT)
                            next_state <= OTP;
                        else
                            next_state <= IDLE;
                      end
                  end
              end

            A1_CAC:
              begin
                if (falling_edge_write)
                  begin
                    if (CLE && !ALE && (Data == 16'hE0))
                      begin
                        if (RD_CACH_ACT ==1'b1)
                            next_state <= RD_CACH;
                        else if (OTP_ACT)
                            next_state <= RD_OTP;
                        else
                            next_state <= RD;
                      end
                    else
                        next_state <= IDLE;
                  end
              end

            ID_PREL:
              begin
                if (falling_edge_write)
                  begin
                    if (ALE  && ((AddrCom == 16'h00) || (AddrCom == 16'h20)))
                        next_state <= ID;
                    else
                        next_state <= IDLE;
                  end
              end

             ID_PREL_PP:
              begin
                if (falling_edge_write)
                  begin
                    if (ALE  && (AddrCom == 16'h00))
                        next_state <= ID_PP;
                    else
                        next_state <= IDLE;
                  end
              end

            ID, ID_PP :
              begin
                if (falling_edge_write)
                  begin
                    if (CLE && !ALE && (Data==8'h00))
                        next_state <= PREL_RD;
                    else if (CLE && !ALE && (Data==16'h90))
                        next_state <= ID_PREL;
                    else if (CLE && !ALE && (Data==16'hEC))
                        next_state <= ID_PREL_PP;
                    else if (CLE && !ALE && (Data==8'h80 && WPNeg))
                        next_state <= PREL_PRG;
                    else if (CLE && !ALE && (Data==8'h60 && WPNeg))
                        next_state <= PREL_ERS;
                    else if (CLE && !ALE && (Data==8'h70))
                        next_state <= IDLE;
                    else if (CLE && !ALE && (Data==8'h29))
                        next_state <= PREL_OTP;
                    else
                        next_state <= IDLE;
                  end
              end

            PREL_PRG:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (ALE)
                        next_state <= A0_PRG;
                    else
                      begin
                        if (OTP_ACT)
                            next_state <= OTP;
                        else
                            next_state <= IDLE;
                      end
                  end
              end

            A0_PRG:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (ALE)
                        next_state <= A1_PRG;
                    else
                      begin
                        if (OTP_ACT)
                            next_state <= OTP;
                        else
                            next_state <= IDLE;
                      end
                  end
              end

            A1_PRG:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if ((ALE && OTP_ACT && (AddrCom[7:6] == 2'b00)) ||
                                                 (ALE && !OTP_ACT))
                        next_state <= A2_PRG;
                    else
                      begin
                        if (OTP_ACT)
                            next_state <= OTP;
                        else
                            next_state <= IDLE;
                      end
                  end
              end

            A2_PRG:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if ((ALE && OTP_ACT && (AddrCom == 8'd0)) ||
                                                 (ALE && !OTP_ACT))
                        next_state <= DATA_PRG;
                    else
                        begin
                        if (OTP_ACT)
                            next_state <= OTP;
                        else
                            next_state <= IDLE;
                      end
                  end
              end

            DATA_PRG:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (CLE && !ALE && (Data == 8'h10))
                        next_state <= PGMS;
                    else if (CLE && !ALE && (Data == 16'h85))
                        next_state <= PGMS_CAC;
                    else if (CLE)
                        next_state <= UNKNOWN;
                    else if (!ALE && !CLE)
                        next_state <= DATA_PRG;
                  end
              end

            PGMS_CAC:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (ALE)
                        next_state <= A0_PRG_CAC;
                    else
                      if (OTP_ACT)
                        next_state <= OTP;
                      else
                        next_state <= IDLE;
                  end
              end

            A0_PRG_CAC:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (ALE)
                        next_state <= DATA_PRG;
                    else
                      if (OTP_ACT)
                        next_state <= OTP;
                      else
                        next_state <= IDLE;
                  end
              end

            PGMS:
              begin
                if (rising_edge_PROG_out)
                  begin
                    if (OTP_ACT)
                        next_state <= OTP;
                    else
                        next_state <= IDLE;
                  end
              end

            PREL_ERS:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (ALE)
                        next_state <= A1_ERS;
                    else
                        next_state <= IDLE;
                  end
              end

            A1_ERS:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (ALE)
                        next_state <= A2_ERS;
                    else
                        next_state <= IDLE;
                  end
              end

            A2_ERS:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (CLE && (Data == 16'hD0))
                        next_state <= ERS_EXEC;
                    else
                        next_state <= IDLE;
                  end
              end

            ERS_EXEC:
              begin
                if (rising_edge_ERS_out)
                  next_state <= IDLE;
              end

            PGD_PREL:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (ALE)
                        next_state <= A0_PGD;
                    else
                        next_state <= IDLE;
                  end
              end

            A0_PGD:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (ALE)
                        next_state <= A1_PGD;
                    else
                        next_state <= IDLE;
                  end
              end

            A1_PGD:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (ALE)
                        next_state <= A2_PGD;
                    else
                        next_state <= IDLE;
                  end
              end

            A2_PGD:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (ALE)
                        next_state <= A3_PGD;
                    else
                        next_state <= IDLE;
                  end
              end

            A3_PGD:
              begin
                if (falling_edge_write && WPNeg)
                  begin
                    if (!ALE && !CLE)
                        next_state <= DATA_PRG;
                    else if (!ALE && CLE && (Data == 16'h10))
                        next_state <= PGMS;
                    else if (!ALE && CLE && (Data == 16'h85))
                        next_state <= PGMS_CAC;
                    else if (CLE)
                        next_state <= IDLE;
                  end
              end

            PREL_OTP:
              begin
                if (falling_edge_write)
                  begin
                    if (CLE && !ALE && (Data == 8'h17))
                        next_state <= OTP_ENTR1;
                    else
                        next_state <= IDLE;
                  end
              end

            OTP_ENTR1:
              begin
                if (falling_edge_write)
                  begin
                    if (CLE && !ALE && (Data == 8'h04))
                        next_state <= OTP_ENTR2;
                    else
                        next_state <= IDLE;
                  end
              end

            OTP_ENTR2:
              begin
                if (falling_edge_write)
                  begin
                    if (CLE && !ALE && (Data == 8'h19))
                        next_state <= OTP;
                    else
                        next_state <= IDLE;
                  end
              end

            OTP:
              begin
                if (falling_edge_write)
                  begin
                    if (CLE && !ALE && (Data==16'h00))
                        next_state <= PREL_RD;
                    else if (CLE && !ALE && (Data==16'h80) && WPNeg)
                        next_state <= PREL_PRG;
                    else
                        next_state <= OTP;
                  end
              end

            endcase

            case (current_state)
            IDLE, PREL_RD, A0_RD, A1_RD, A2_RD,
            RD_WCMD, BUFF_TR, RD, CAC_PREL, A0_CAC, A1_CAC,
            ID_PREL, ID, PREL_PRG, PGD_PREL, A0_PRG, A1_PRG,
            A2_PRG, DATA_PRG, PGMS_CAC, A0_PRG_CAC,
            PGMS, PREL_ERS, A1_ERS, A2_ERS, ERS_EXEC,
            A0_PGD, A1_PGD, A2_PGD, A3_PGD,
            PREL_OTP, OTP_ENTR1, OTP_ENTR2, OTP,
            CBSYR, RD_CACH, WFRD, RD_OTP, ID_PP, ID_PREL_PP:
              begin
                if (falling_edge_write)
                  begin
                    if (CLE && !ALE && (Data == 16'hFF))
                            next_state <= RESET;
                  end
              end
            endcase

            if ((current_state==PGMS) || (current_state==ERS_EXEC))
              begin
                if (!WP_D)
                  next_state <= RESET;
              end

            if ((current_state==IDLE) || (current_state==RD) ||
                (current_state==ID))
              begin
                if (falling_edge_write && !WPNeg && CLE && !ALE &&
                (Data == 16'h60))
                    next_state <= current_state;
              end

            if ((current_state==IDLE) || (current_state==RD) ||
                (current_state==ID) || (current_state==OTP)
                || (current_state==RD_OTP))
              begin
                if (falling_edge_write && !WPNeg && CLE && !ALE &&
                (Data == 16'h80))
                    next_state <= current_state;
              end

    end

    ///////////////////////////////////////////////////////////////////////////
    //FSM Output generation and general funcionality
    ///////////////////////////////////////////////////////////////////////////
    always @(posedge read)
    begin
          ->oe_event;
    end

    always @(oe_event)
    begin
        oe = 1'b1;
        #1 oe = 1'b0;
    end

    always @(oe or falling_edge_write or rising_edge_reseted or current_state or
            RENeg or CENeg or rising_edge_TR_out or rising_edge_CBSYR_out or
            rising_edge_PROG_out or rising_edge_ERS_out or
            PRG_ACT or rising_edge_RSTDONE or WP_D or
            rising_edge_WENeg or falling_edge_WENeg)
    begin: Functional

        Status[7] = WPNeg;
        if (!reseted)
            RY_zd <= 1'b1;
        else
            case (current_state)
                IDLE:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        Id_ONFI = 1'b0;
                        if (CLE && !ALE && (Data == 16'h70))
                            STAT_ACT <= 1'b1;
                        else if (CLE && !ALE && (Data == 16'h00))
                            STAT_ACT <= 1'b0;
                        else if (CLE && !ALE && (Data == 16'h90))
                            STAT_ACT <= 1'b0;
                        else if (CLE && !ALE && (Data == 16'hEC))
                            STAT_ACT <= 1'b0;
                        else if (CLE && !ALE && (Data == 16'h29))
                            STAT_ACT <= 1'b0;
                        else if (CLE && !ALE && (Data == 16'h80) && WPNeg)
                            STAT_ACT <= 1'b0;
                        else if (CLE && !ALE && (Data==16'h60) && WPNeg)
                            STAT_ACT <= 1'b0;
                        else
                            STAT_ACT <= 1'b0;
                      end

                    if (oe && STAT_ACT)
                            DOut_zd <= Status;
                  end

                UNKNOWN:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'hFF))
                          begin
                            STAT_ACT <= 1'b0;
                            RSTSTART <= 1'b1;
                            RSTSTART <= #1 1'b0;
                            RY_zd <= 1'b0;
                            Status[6:5] = 2'b00;
                            Status[1:0] = 2'b00;
                            ERS_ACT <= 1'b0;
                            PGD_ACT <= 1'b0;
                            PGR_ACT <= 1'b0;
                            PRG_ACT <= 1'b0;
                            RD_CACH_ACT <= 1'b0;
                            RD_CACH_LAST <= 1'b0;
                            OTP_ACT <= 1'b0;
                            Status[5] = 1'b1;
                            PROG_in <= 1'b0;
                            TR_in <= 1'b0;
                            CBSYR_in <= 1'b0;
                            ERS_in <= 1'b0;
                          end
                      end
                  end

                RESET:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'h70))
                            STAT_ACT <= 1'b1;
                      end
                    if (rising_edge_RSTDONE)
                      begin
                        RY_zd <= 1'b1;
                        Status[6:5] = 2'b11;
                        Status[1:0] = 2'b00;
                        PRG_ACT <= 1'b0;
                        ERS_ACT <= 1'b0;
                        PGD_ACT <= 1'b0;
                        PGR_ACT  <= 1'b0;
                        RD_CACH_ACT <= 1'b0;
                        RD_CACH_LAST <= 1'b0;
                        OTP_ACT <= 1'b0;
                        PROG_in <= 1'b0;
                        TR_in <= 1'b0;
                        CBSYR_in <= 1'b0;
                        ERS_in <= 1'b0;
                        Id_ONFI = 1'b0;
                      end
                    if (oe)
                      begin
                        if (STAT_ACT)
                            DOut_zd <= Status;
                      end
                  end

                PREL_RD:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                            ColAddr[7:0] = AddrCom;
                      end
                  end

                A0_RD:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                            ColAddr[15:8] = AddrCom;
                      end
                  end

                A1_RD:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                            RowAddr[7:0] = AddrCom;
                      end
                  end

                A2_RD:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                          begin
                            RowAddr[15:8] = AddrCom;
                            RowAddr[23:16] = 8'h00;
                            getPage(RowAddr);
                            getAddress(ColAddr);
                          end
                      end
                  end

                RD_WCMD:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'h30))
                          begin
                            PGR_ACT  <= 1'b1;
                            RdPage = TmpPage;
                            RdBlck = TmpBlck;
                            RdAddr = AddrWithinPage;
                            RdSeg  = TmpSegm;
                            CRdPage = TmpPage;
                            CRdAddr = 0;
                            CPageWithinBlock = PageWithinBlock;
                            FrstCachRd = 1'b1;
                            TR_in <= 1'b1;
                            RY_zd <= 1'b0;
                            Status[6:5] = 2'b00;
                          end

                        else if (CLE && !ALE && (Data == 16'h35))
                          begin
                            PGD_ACT <= 1'b1;
                            PGR_ACT  <= 1'b1;
                            TR_in <= 1'b1;
                            RY_zd <= 1'b0;
                            Status[6:5] = 2'b00;
                            getPage(RowAddr);
                            getAddress(ColAddr);
                            RdPage = TmpPage;
                            RdBlck = TmpBlck;
                            RdAddr = AddrWithinPage;

                            for (i=0; i<=PageSize; i=i+1)
                                PDBuffer[i] = -1;
                          end
                      end
                  end

                BUFF_TR:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'h70))
                            STAT_ACT <= 1'b1;
                      end
                    else if (rising_edge_TR_out)
                      begin
                        PGR_ACT <= 1'b0;
                        RY_zd     <= 1'b1;
                        Status[6:5]= 2'b11;
                        TR_in    <= 1'b0;
                        if (PGD_ACT)
                          begin
                            for (i=0; i<=PageSize; i=i+1)
                              begin
                                memory_features_i0.read_mem_w(
                                            memory_read_data,
                                            RdPage * (PageSize + 1) + i
                                            );
                                PDBuffer[i] = memory_read_data;
                              end
                          end
                      end

                    if (oe)
                      begin
                        if (STAT_ACT)
                          DOut_zd <= Status;
                      end
                  end

                RD:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'h00))
                          begin
                            STAT_ACT <= 1'b0;
                            if (!STAT_ACT)
                              begin
                                RD_CACH_ACT <= 1'b0;
                                RD_CACH_LAST <= 1'b0;
                              end
                          end
                        else if (CLE && !ALE && (Data == 16'h70))
                            STAT_ACT <= 1'b1;
                        else if (CLE && !ALE && (Data == 16'h90)
                        && !PGD_ACT)
                          begin
                            STAT_ACT <= 1'b0;
                            RD_CACH_ACT <= 1'b0;
                            RD_CACH_LAST <= 1'b0;
                          end
                        else if (CLE && !ALE && (Data == 16'hEC)
                        && !PGD_ACT)
                          begin
                            STAT_ACT <= 1'b0;
                            RD_CACH_ACT <= 1'b0;
                            RD_CACH_LAST <= 1'b0;
                          end
                        else if (CLE && !ALE && (Data == 16'h80)
                            && !PGD_ACT && WPNeg)
                          begin
                            STAT_ACT <= 1'b0;
                            RD_CACH_ACT <= 1'b0;
                            RD_CACH_LAST <= 1'b0;
                          end
                        else if (CLE && !ALE && (Data == 16'h60)
                            && !PGD_ACT && WPNeg)
                          begin
                            STAT_ACT <= 1'b0;
                            RD_CACH_ACT <= 1'b0;
                            RD_CACH_LAST <= 1'b0;
                          end
                        else if (CLE && !ALE && (Data == 16'h29)
                            && !PGD_ACT)
                          begin
                            STAT_ACT <= 1'b0;
                            RD_CACH_ACT <= 1'b0;
                            RD_CACH_LAST <= 1'b0;
                          end
                        else if (CLE && !ALE && (Data == 16'h85) && PGD_ACT)
                            STAT_ACT <= 1'b0;
                        else if (CLE && !ALE && (Data == 16'h05) && !PGD_ACT)
                            STAT_ACT <= 1'b0;
                        else if (CLE && !ALE && (Data == 16'h31) && !PGD_ACT &&
                                                           !RD_CACH_ACT)
                          begin
                            STAT_ACT <= 1'b0;
                            RD_CACH_ACT <= 1'b1;
                            CBSYR_in <= 1'b1;
                            RY_zd <= 1'b0;
                            Status[6] = 1'b0;
                          end
                        else
                          begin
                            STAT_ACT <= 1'b0;
                            PGD_ACT <= 1'b0;
                          end
                      end
                    if (oe)
                      begin
                        if (!STAT_ACT)
                          begin
                            if (RD_CACH_ACT)
                                Read_Data(CRdPage, CRdAddr);
                            else
                                Read_Data(RdPage, RdAddr);
                           end
                        else if (STAT_ACT)
                            DOut_zd <= Status;
                      end
                  end

                RD_OTP:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'h00))
                            STAT_ACT <= 1'b0;
                        else if (CLE && !ALE && (Data == 16'h70))
                            STAT_ACT <= 1'b1;
                        else if (CLE && !ALE && (Data == 16'h80) && WPNeg)
                            STAT_ACT <= 1'b0;
                        else
                            STAT_ACT <= 1'b0;
                      end
                    if (oe)
                      begin
                        if (!STAT_ACT)
                            Read_OTP(RdPage, RdAddr);
                        else if (STAT_ACT)
                            DOut_zd <= Status;
                      end
                  end

                CBSYR:
                  begin
                     if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'h70))
                            STAT_ACT <= 1'b1;
                      end
                    if (rising_edge_CBSYR_out)
                      begin
                        CBSYR_in = 1'b0;
                        RY_zd <= 1'b1;
                        Status[6] = 1'b1;
                        if (FrstCachRd)
                          FrstCachRd = 1'b0;
                        else
                          begin
                            CPageWithinBlock = CPageWithinBlock + 1;
                            if (CPageWithinBlock < 64)
                                CRdPage = CRdPage + 1;
                            CRdAddr = 0;
                          end
                        if (!RD_CACH_LAST)
                          begin
                            TR_in = 1'b1;
                            Status[5] = 1'b0;
                          end
                      end

                      if (oe)
                          if (STAT_ACT)
                              DOut_zd <= Status;
                  end

                RD_CACH:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'h3F))
                          begin
                            RD_CACH_LAST= 1'b1;
                            STAT_ACT <= 1'b0;
                          end
                        if (CLE && !ALE &&
                        ((Data == 16'h31) || (Data == 16'h3F))
                            && TR_in == 1'b0)
                          begin
                            CBSYR_in <= 1'b1;
                            RY_zd <= 1'b0;
                            Status[6] = 1'b0;
                            STAT_ACT <= 1'b0;
                          end
                        else if (CLE && !ALE && (Data == 16'h70))
                            STAT_ACT <= 1'b1;
                        else if (CLE && !ALE && (Data == 16'h00))
                            STAT_ACT <= 1'b0;
                        else if (CLE && !ALE && (Data == 16'h05))
                            STAT_ACT <= 1'b0;
                      end
                    if (rising_edge_TR_out)
                      begin
                        TR_in = 1'b0;
                        Status[5] = 1'b1;
                      end

                    if (oe)
                      begin
                        if (!STAT_ACT)
                          Read_Data(CRdPage, CRdAddr);
                        else if (STAT_ACT)
                          DOut_zd <= Status;
                      end
                  end

                WFRD:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'h70))
                            STAT_ACT <= 1'b1;
                      end

                    if (rising_edge_TR_out)
                      begin
                        TR_in = 1'b0;
                        Status[5] = 1'b1;
                        CBSYR_in <= 1'b1;
                        RY_zd <= 1'b0;
                        Status[6] = 1'b0;
                      end

                    if (oe)
                      begin
                        if (STAT_ACT)
                          DOut_zd <= Status;
                      end
                  end

                CAC_PREL:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                            ColAddr[7:0] = AddrCom;
                      end
                  end

                A0_CAC:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                            ColAddr[15:8] = AddrCom;
                      end
                  end

                A1_CAC:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'hE0))
                          begin
                            getAddress(ColAddr);
                            RdAddr = AddrWithinPage;
                            CRdAddr = AddrWithinPage;
                          end
                      end
                  end
                ID_PREL:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE && ((AddrCom == 0) || (AddrCom == 16'h20)))
                          begin
                            IDAddr <= 0;
                            Id_ONFI = 1'b0;
                            if (AddrCom == 16'h20)
                                 Id_ONFI = 1'b1;
                          end
                      end
                  end

                ID_PREL_PP:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE && (AddrCom == 0))
                            IDAddr <= 0;
                      end
                  end
                ID:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        Id_ONFI = 1'b0;
                        if (CLE && !ALE && (Data==16'h70))
                            STAT_ACT <= 1'b1;
                        else
                            STAT_ACT <= 1'b0;
                      end
                    if (oe)
                      begin
                          if (IDAddr < 4 && !Id_ONFI)
                            begin
                              DOut_zd <= IDArray[IDAddr];
                              IDAddr <= IDAddr+1;
                            end
                          else if (IDAddr < 4 && Id_ONFI)
                            begin
                              DOut_zd <= ONFIArray[IDAddr];
                              IDAddr <= IDAddr+1;
                            end
                          else
                              DOut_zd <= 8'bZ;
                      end
                  end

                ID_PP:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data==16'h70))
                            STAT_ACT <= 1'b1;
                        else
                            STAT_ACT <= 1'b0;
                      end
                    if (oe)
                      begin
                          if (IDAddr < 768 )
                            begin
                              DOut_zd <= PPageArray[IDAddr];
                              IDAddr <= IDAddr+1;
                            end
                          else
                              DOut_zd <= 8'bZ;

                      end
                  end

                PREL_PRG:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                            ColAddr[7:0] = AddrCom;
                      end
                  end

                A0_PRG:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                          begin
                            ColAddr[15:8] = AddrCom;
                            getAddress(ColAddr);
                            WrAddr = AddrWithinPage;
                            WrSeg  = TmpSegm;
                          end
                      end
                  end

                A1_PRG:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                            RowAddr[7 : 0] = AddrCom;
                      end
                  end

                A2_PRG:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                          begin
                            RowAddr[15 : 8] = AddrCom;
                            RowAddr[23 : 16]= 8'b0;
                            getPage(RowAddr);
                            WrPage = TmpPage;
                            WrBlck = TmpBlck;
                            for (j=0; j<=PageSize; j=j+1)
                                CashBuffData[j] = -1;
                            for (j=0; j<=SegmentNum; j=j+1)
                                if (OTP_ACT)
                                    SegForProg[j] = OTPProgramedFlag[WrPage*
                                                            (SegmentNum+1)+j];
                                else
                                    SegForProg[j] = ProgramedFlag[WrPage*
                                                            (SegmentNum+1)+j];
                            SegProgSt = 8'b0;
                          end
                      end
                  end

                DATA_PRG:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (!ALE && !CLE && (WrAddr <= PageSize))
                          begin
                            getSegment(WrAddr,WrSeg);
                            if (((ProgramedFlag[WrPage*(SegmentNum+1)
                                              +WrSeg]==1'b0) && !OTP_ACT) ||
                                ((OTPProgramedFlag[WrPage*(SegmentNum+1)
                                              +WrSeg]==1'b0) && OTP_ACT))
                            begin
                                CashBuffData[WrAddr] = Data;
                                SegForProg[WrSeg] = 1'b1;
                                SegProgSt[WrSeg] = 1'b1;
                            end
                            WrAddr = WrAddr+1;
                          end
                        else if (CLE && !ALE && (Data==16'h10))
                          begin
                            PRG_ACT <= 1'b1;
                            PROG_in <= 1'b1;
                            RY_zd <= 1'b0;
                            Status[6:5] = 2'b00;
                            firstFlag = 1'b1;
                            if (|SegProgSt)
                                prog_time = page_prog_time;
                            else
                                prog_time = 1;
                          end
                      end
                  end

                PGMS_CAC:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                            ColAddr[7 : 0] = AddrCom;
                      end
                  end
                A0_PRG_CAC:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                          begin
                            ColAddr[15:8] = AddrCom;
                            getAddress(ColAddr);
                            WrAddr = AddrWithinPage;
                            WrSeg  = TmpSegm;
                          end
                      end
                  end

                PGMS:
                  begin
                    if (firstFlag )
                      begin
                        firstFlag = 1'b0;
                        if (!OTP_ACT)
                          begin
                            for (j=0; j<=PageSize; j=j+1)
                              begin
                                getSegment(j, WrSeg);
                                if ((ProgramedFlag
                                  [WrPage*(SegmentNum+1)+WrSeg]==1'b0)
                                  && (CashBuffData[j] != -1))
                                    memory_features_i0.write_mem_w(
                                            WrPage * (PageSize + 1) + j,
                                            -1);
                                else
                                  CashBuffData[j] = -1;
                              end
                          end
                        else
                          begin
                            for (j=0; j<=PageSize; j=j+1)
                              begin
                                getSegment(j, WrSeg);
                                if ((OTPProgramedFlag
                                   [WrPage*(SegmentNum+1)+WrSeg]==1'b0)
                                   && (CashBuffData[j] != -1))
                                    OTP_Area[WrPage*(PageSize+1)+j] = -1;
                                else
                                    CashBuffData[j] = -1;
                              end
                          end

                        for (j=0; j<=PageSize; j=j+1)
                                WrBuffData[j] = CashBuffData[j];
                        ProgPage = WrPage;
                        ProgBlck = WrBlck;
                      end
                    if (rising_edge_PROG_out)
                      begin
                        RY_zd <= 1'b1;
                        PGD_ACT <= 1'b0;
                        PRG_ACT <= 1'b0;
                        Status[6:5] = 2'b11;
                        PROG_in <= 1'b0;
                        Status[1:0] = 2'b00;

                            if (!OTP_ACT)
                              begin
                                for (j=0; j<=PageSize; j=j+1)
                                  begin
                                    getSegment(j,pom_seg);
                                    if (ProgramedFlag[ProgPage*(SegmentNum+1)
                                                                +pom_seg]==1'b0
                                        && (WrBuffData[j] != -1))
                                          memory_features_i0.write_mem_w(
                                            WrPage * (PageSize + 1) + j,
                                            WrBuffData[j]);
                                  end
                                  for (j=0; j<=SegmentNum; j=j+1)
                                    ProgramedFlag[ProgPage*(SegmentNum+1)+j]
                                                        = SegForProg[j];
                              end
                            else
                              begin
                                for (j=0; j<=PageSize; j=j+1)
                                  begin
                                    getSegment(j,pom_seg);
                                    if (OTPProgramedFlag[ProgPage*(SegmentNum+1)
                                                                +pom_seg]==1'b0
                                        && (WrBuffData[j] != -1))
                                        OTP_Area[ProgPage*(PageSize+1)+j]
                                                               = WrBuffData[j];
                                  end
                                  for (j=0; j<=SegmentNum; j=j+1)
                                    OTPProgramedFlag[ProgPage*(SegmentNum+1)+j]
                                                        = SegForProg[j];
                              end
                      end
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'h70))
                            STAT_ACT <= 1'b1;// read status
                      end
                    if (oe)
                        if (STAT_ACT)
                            DOut_zd <= Status;
                  end

                PREL_ERS:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                            RowAddr[7 : 0] = AddrCom;
                      end
                  end

                A1_ERS:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                          begin
                            RowAddr[15 : 8]  = AddrCom;
                            RowAddr[23 : 16] = 8'b0;
                          end
                      end
                  end

                A2_ERS:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'hD0))
                          begin
                                getPage(RowAddr);
                                ErsBlck = TmpBlck;
                                for (i=ErsBlck*PageNumInBl;
                                    i<= (ErsBlck*PageNumInBl)+BlockSize;
                                    i=i+1)
                                  begin
                                          memory_features_i0.corrupt_mem_w(
                                            i * (PageSize + 1),
                                            i * (PageSize + 1) + PageSize
                                            );
                                    for (j=0; j<=SegmentNum; j=j+1)
                                        ProgramedFlag[i*(SegmentNum+1)+j]=1'b0;
                                  end
                                ERS_in <= 1'b1;
                                ERS_ACT = 1'b1;
                                RY_zd <= 1'b0;
                                Status[6:5] = 2'b00;
                          end
                      end
                  end

                ERS_EXEC:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data == 16'h70) )
                            STAT_ACT <= 1'b1;
                      end
                    if (rising_edge_ERS_out)
                      begin
                        for (i=ErsBlck*PageNumInBl;
                                        i<= (ErsBlck*PageNumInBl)+BlockSize;
                                        i=i+1)
                          begin
                             memory_features_i0.erase_mem_w(
                             i * (PageSize + 1),
                             i * (PageSize + 1) + PageSize
                             );
                            for (j=0; j<=SegmentNum; j=j+1)
                                ProgramedFlag[i*(SegmentNum+1)+j] = 1'b0;
                          end
                        ERS_ACT = 1'b0;
                        ERS_in <= 1'b0;
                        RY_zd <= 1'b1;
                        Status[6:5] = 2'b11;
                        Status[1:0] = 2'b00;
                      end
                    if (oe)
                        if (STAT_ACT)
                            DOut_zd <= Status;
                  end

                PGD_PREL:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                            ColAddr[7:0] = AddrCom;
                      end
                  end

                A0_PGD:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                          begin
                            ColAddr[15 : 8] = AddrCom;
                            getAddress(ColAddr);
                            WrAddr = AddrWithinPage;
                            WrSeg  = TmpSegm;
                          end
                      end
                  end

                A1_PGD:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                            RowAddr[7 : 0] = AddrCom;
                      end
                  end

                A2_PGD:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (ALE)
                          begin
                            RowAddr[15 : 8] = AddrCom;
                            RowAddr[23 : 16]= 8'b0;
                            getPage(RowAddr);
                            WrPage = TmpPage;
                            WrBlck = TmpBlck;
                            for (j=0; j<=PageSize; j=j+1)
                                CashBuffData[j] = PDBuffer[j];
                            for (j=0; j<=SegmentNum; j=j+1)
                              begin
                                SegForProg[j] = 1'b1;
                                SegProgSt[j] = 1'b1;
                              end
                          end
                      end
                  end
                A3_PGD:
                  begin
                    if (falling_edge_write && flagWRITE && WPNeg)
                      begin
                        flagWRITE = 1'b0;
                        if (!ALE && !CLE && (WrAddr <= PageSize))
                          begin
                            getSegment(WrAddr, WrSeg);
                            if (ProgramedFlag[WrPage*(SegmentNum+1)
                                                                +WrSeg]==1'b0)
                                CashBuffData[WrAddr] = Data;
                            SegForProg[WrSeg] = 1'b1;
                            WrAddr = WrAddr+1;
                          end
                        else if (!ALE && CLE && (Data==16'h10))
                          begin
                            PRG_ACT <= 1'b1;
                            PROG_in <= 1'b1;
                            RY_zd <= 1'b0;
                            Status[6:5] = 2'b00;
                            firstFlag = 1'b1;
                            prog_time = page_prog_time;
                          end
                      end
                  end

                PREL_OTP:
                  begin
                  end
                OTP_ENTR1:
                  begin
                  end
                OTP_ENTR2:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (!ALE && CLE && (Data == 16'h19))
                            OTP_ACT <= 1'b1;
                      end
                  end

                OTP:
                  begin
                    if (falling_edge_write && flagWRITE)
                      begin
                        flagWRITE = 1'b0;
                        if (CLE && !ALE && (Data==16'h70))
                            STAT_ACT <= 1'b1;
                        else
                            STAT_ACT <= 1'b0;
                      end

                    if (oe)
                        if (STAT_ACT)
                            DOut_zd <= Status;
                  end
        endcase

        if (RENeg || CENeg)
            DOut_zd <= 8'bZ;

        if ((falling_edge_write && CLE && !ALE && (Data == 16'hFF) &&
           (RSTDONE != 1'b0)) || (!WP_D &&
           ((current_state == PGMS) || (current_state == ERS_EXEC))))
         begin
           STAT_ACT <= 1'b0;
           RSTSTART <= 1'b1;
           RSTSTART <= #1 1'b0;
           RY_zd = 1'b0;
           Status[6:5] = 2'b00;
           Status[1:0] = 2'b00;
        end

        if (falling_edge_WENeg &&
        ((current_state == A2_PRG) || (current_state == A0_PRG_CAC)) )
          tADL_check = 1'b1;
        else if (rising_edge_WENeg && ((current_state == DATA_PRG) ||
        (current_state == PGMS) || (current_state == IDLE) ||
        (current_state == UNKNOWN) || (current_state == RESET)))
           tADL_check = 1'b0;

        for (j=0; j<=PageNum; j=j+1)
          for (i=0; i<=3; i=i+1)
            begin
              if(ProgramedFlag[j*(SegmentNum+1)+i])
                ProgramedFlag[j*(SegmentNum+1)+i+4] = 1'b1;
              if(ProgramedFlag[j*(SegmentNum+1)+i+4])
                ProgramedFlag[j*(SegmentNum+1)+i] = 1'b1;
            end

        for (j=0; j<=OTPPageNum; j=j+1)
          for (i=0; i<=3; i=i+1)
            begin
              if(OTPProgramedFlag[j*(SegmentNum+1)+i])
                OTPProgramedFlag[j*(SegmentNum+1)+i+4] = 1'b1;
              if(OTPProgramedFlag[j*(SegmentNum+1)+i+4])
                OTPProgramedFlag[j*(SegmentNum+1)+i] = 1'b1;
            end

    end

    //Program Operation
    always @(posedge PROG_in)
    begin:ProgTime
        #(prog_time) PROG_out <= 1'b1;
    end
    always @(negedge PROG_in)
    begin
        disable ProgTime;
        #1 PROG_out <= 1'b0;
    end

        //Erase Operation
    always @(posedge ERS_in)
    begin:ErsTime
        #(erase_time) ERS_out <= 1'b1;
    end
    always @(negedge ERS_in)
    begin
        disable ErsTime;
        #1 ERS_out <= 1'b0;
    end

    //Page read
    always @(posedge TR_in)
    begin:PageRead
        TR_out = 1'b0;
        #(tdevice_TR) TR_out = 1'b1;
    end
    always @(negedge TR_in)
    begin
        disable PageRead;
        #1 TR_out = 1'b0;
    end

    //Read Cache
    always @(posedge CBSYR_in)
    begin:CacheRead
        #(tdevice_CBSYR) CBSYR_out <= 1'b1;
    end
    always @(negedge CBSYR_in)
    begin
        disable CacheRead;
        #1 CBSYR_out <= 1'b0;
    end

    // determining rising/falling edges of signals
    always @(posedge PoweredUp)
        begin
            rising_edge_PoweredUp <= 1'b1;
            #1 rising_edge_PoweredUp <= 1'b0;
        end

    always @(posedge reseted)
        begin
            rising_edge_reseted = 1'b1;
            #1 rising_edge_reseted = 1'b0;
        end

    always @(posedge RSTSTART)
        begin
            rising_edge_RSTSTART = 1'b1;
            #1 rising_edge_RSTSTART = 1'b0;
        end

    always @(posedge RSTDONE)
        begin
            rising_edge_RSTDONE = 1'b1;
            #1 rising_edge_RSTDONE = 1'b0;
        end

    always @(negedge write)
        begin
            falling_edge_write <= 1'b1;
            #1 falling_edge_write <= 1'b0;
        end

    always @(negedge falling_edge_write)
        begin
          flagWRITE = 1'b1;
        end

    always @(posedge ERS_out)
        begin
            rising_edge_ERS_out = 1'b1;
            #1 rising_edge_ERS_out = 1'b0;
        end

    always @(posedge TR_out)
        begin
            rising_edge_TR_out = 1'b1;
            #1 rising_edge_TR_out = 1'b0;
        end

    always @(posedge PROG_out)
        begin
            rising_edge_PROG_out = 1'b1;
            #1 rising_edge_PROG_out = 1'b0;
        end

    always @(posedge CBSYR_out)
        begin
            rising_edge_CBSYR_out = 1'b1;
            #1 rising_edge_CBSYR_out = 1'b0;
        end

     always @(posedge WENeg)
        begin
            #1 rising_edge_WENeg = 1'b1;
            #2 rising_edge_WENeg = 1'b0;
        end

     always @(negedge WENeg)
        begin
            falling_edge_WENeg = 1'b1;
            #1 falling_edge_WENeg = 1'b0;
        end

    always @(negedge WPNeg )
    begin: WPtiming
        #(100) WP_D = 1'b0;
    end

    always @(posedge WPNeg)
    begin
        disable WPtiming;
        #1 WP_D = 1'b1;
    end

task getSegment (input integer paddress,
                output integer j);
    begin
        for (i = 0; i<= SegmentNum; i = i+1)
          begin
            if ((paddress >= ssa[i]) && (paddress <= sea[i]))
                j = i;
          end
    end
endtask

task Read_Data (input integer Page,
                inout integer Addr);
    integer memory_read_data_internal;
    begin
        memory_features_i0.read_mem_w(
                memory_read_data_internal,
                Page * (PageSize+1) + Addr);
        if (memory_read_data_internal != -1)
            DOut_zd <= memory_read_data_internal;
        else
            DOut_zd <= 8'bX;

        if (Addr != PageSize)
            Addr = Addr+1;
    end
endtask

task Read_OTP (input integer Page,
                inout integer Addr);
    begin
        if (Page <= BlockSize)
            begin
                if (OTP_Area[Page*(PageSize+1) + Addr] != -1)
                    DOut_zd <= OTP_Area[Page*(PageSize+1) + Addr];
                else
                    DOut_zd <= 8'bX;
            end
        else
            DOut_zd <= 8'hFF;

        if (Addr != PageSize)
            Addr = Addr+1;
    end

endtask

task getAddress (input reg[15:0] Column);
    begin
        if (Column[MainAreaAddBit] == 1'b0)
            begin
                TmpSegm = Column[HAddBitSeg : HAddBitSeg-1];
                AddrWithinPage = Column;
            end
        else
            begin
                TmpSegm = MainSize/SegmentSize + Column[HAddBitSpareSeg
                                                            :HAddBitSpareSeg-1];
                AddrWithinPage = MainSize + Column[HAddBitSpareSeg : 0];
            end
    end
endtask

task getPage (input reg[23:0] Row);
    begin
        PageWithinBlock = Row[HAddBitPag-MainAreaAddBit-1 : 0];
        TmpBlck = Row[HAddBitBl-MainAreaAddBit-1:HAddBitPag-MainAreaAddBit];
        TmpPage = TmpBlck*PageNumInBl + PageWithinBlock;
    end
endtask

    initial
    begin
        //////////////////////////////////////////////////////////////////
        //ID array data / s34ml01g1 DEVICE SPECIFIC
        //////////////////////////////////////////////////////////////////
        IDArray[0] = 8'h01;
        IDArray[1] = 8'hF1;
        IDArray[2] = 8'h00;
        IDArray[3] = 8'h1D;

        ONFIArray[0] = 8'h4F;
        ONFIArray[1] = 8'h4E;
        ONFIArray[2] = 8'h46;
        ONFIArray[3] = 8'h49;

        PPageArray[0] = 8'h4F;
        PPageArray[1] = 8'h4E;
        PPageArray[2] = 8'h46;
        PPageArray[3] = 8'h49;
        PPageArray[4] = 8'h02;
        PPageArray[5] = 8'h00;
        PPageArray[6] = 8'h14;
        PPageArray[7] = 8'h00;
        PPageArray[8] = 8'h12;
        for (i=9; i<= 31; i=i+1)
            PPageArray[i] = 8'h00;
        PPageArray[32] = 8'h53;
        PPageArray[33] = 8'h50;
        PPageArray[34] = 8'h41;
        PPageArray[35] = 8'h4E;
        PPageArray[36] = 8'h53;
        PPageArray[37] = 8'h49;
        PPageArray[38] = 8'h4F;
        PPageArray[39] = 8'h4E;
        PPageArray[40] = 8'h20;
        PPageArray[41] = 8'h20;
        PPageArray[42] = 8'h20;
        PPageArray[43] = 8'h20;
        PPageArray[44] = 8'h53;
        PPageArray[45] = 8'h33;
        PPageArray[46] = 8'h34;
        PPageArray[47] = 8'h4D;
        PPageArray[48] = 8'h4C;
        PPageArray[49] = 8'h30;
        PPageArray[50] = 8'h31;
        PPageArray[51] = 8'h47;
        PPageArray[52] = 8'h31;
        for (i=53; i<= 63; i=i+1)
            PPageArray[i] = 8'h20;
        PPageArray[64] = 8'h01;
        for (i=65; i<= 80; i=i+1)
            PPageArray[i] = 8'h00;
        PPageArray[81] = 8'h08;
        PPageArray[82] = 8'h00;
        PPageArray[83] = 8'h00;
        PPageArray[84] = 8'h40;
        PPageArray[85] = 8'h00;
        PPageArray[86] = 8'h00;
        PPageArray[87] = 8'h02;
        PPageArray[88] = 8'h00;
        PPageArray[89] = 8'h00;
        PPageArray[90] = 8'h10;
        PPageArray[91] = 8'h00;
        PPageArray[92] = 8'h40;
        PPageArray[93] = 8'h00;
        PPageArray[94] = 8'h00;
        PPageArray[95] = 8'h00;
        PPageArray[96] = 8'h00;
        PPageArray[97] = 8'h04;
        PPageArray[98] = 8'h00;
        PPageArray[99] = 8'h00;
        PPageArray[100] = 8'h01;
        PPageArray[101] = 8'h22;
        PPageArray[102] = 8'h01;
        PPageArray[103] = 8'h14;
        PPageArray[104] = 8'h00;
        PPageArray[105] = 8'h01;
        PPageArray[106] = 8'h05;
        PPageArray[107] = 8'h01;
        PPageArray[108] = 8'h01;
        PPageArray[109] = 8'h03;
        PPageArray[110] = 8'h04;
        PPageArray[111] = 8'h00;
        PPageArray[112] = 8'h01;
        PPageArray[113] = 8'h00;
        PPageArray[114] = 8'h00;
        for (i=115; i<= 127; i=i+1)
            PPageArray[i] = 8'h00;
        PPageArray[128] = 8'h0A;
        PPageArray[129] = 8'h07;
        PPageArray[130] = 8'h06;
        PPageArray[131] = 8'h07;
        PPageArray[132] = 8'h00;
        PPageArray[133] = 8'hBC;
        PPageArray[134] = 8'h02;
        PPageArray[135] = 8'hB8;
        PPageArray[136] = 8'h0B;
        PPageArray[137] = 8'h19;
        PPageArray[138] = 8'h00;
        PPageArray[139] = 8'h64;
        PPageArray[140] = 8'h00;
        for (i=141; i<= 163; i=i+1)
            PPageArray[i] = 8'h00;
        PPageArray[164] = 8'h00;
        PPageArray[165] = 8'h00;
        for (i=166; i<= 253; i=i+1)
            PPageArray[i] = 8'h00;
        PPageArray[254] = 8'h57;
        PPageArray[255] = 8'h5F;
        for (i=256; i<= 511; i=i+1)
            PPageArray[i] = PPageArray[i-256];
        for (i=512; i<= 767; i=i+1)
            PPageArray[i] = PPageArray[i-512];
    end

// extracting time parameter from sdf
reg  BuffInR;
wire BuffOutR;

    BUFFER    BUFR           (BuffOutR   , BuffInR);

    initial
    begin
        BuffInR     = 1'b1;
    end

    always @(posedge BuffOutR)
    begin
        WER_01   = $time;
    end

endmodule

module BUFFER (OUT,IN);
    input IN;
    output OUT;
    buf   ( OUT, IN);
endmodule

module memory_features();
    // -------------------------------------------------------------------------
    // ----------------    start of memory management section    ---------------
    // -------------------------------------------------------------------------

    // memory partitioning parameters
    parameter list_num       = 1024;
    parameter list_size      = 20'h21000;
    // memory initial data value
    parameter MaxData        = 8'hFF;

    // memory management routines
    // handle dynamic memory allocation

    // abstract memory region model
    class linked_list_c;
        // memory element model
        reg[31:0] key_address;
        integer val_data;
        // organize memory storage elements into a linked list
        linked_list_c successor;

        function new(
            integer address_a,
            integer data_a);
        begin
            key_address = address_a;
            val_data = data_a;
            successor = null;
        end
        endfunction
    endclass

    // partition memory region for faster access
    linked_list_c linked_list [list_num];
    // class methods internal communication pool
    linked_list_c found;
    linked_list_c prev;
    linked_list_c sub_linked_list;
    linked_list_c sub_linked_list_last;

    // low-level routines
    class low_level_interface_c;

        // assure proper initialization
        function new;
            integer new_iter;
        begin
            // initialize linked list handles
            for(new_iter=0; new_iter < list_num; new_iter = new_iter + 1)
                linked_list[new_iter] = null;
            found = null;
            prev = null;
            sub_linked_list = null;
            sub_linked_list_last = null;
        end
        endfunction

        // Iterate through linked listed comapring key values
        // Stop when key value greater or equal
        task position_list(
            integer address_a,
            linked_list_c root);
        begin
            found = root;
            prev = null;
            while ((found != null) && (found.key_address < address_a))
            begin
                prev = found;
                found = found.successor;
            end
        end
        endtask

        // Add new element to a linked list
        task insert_list(
            integer address_a,
            integer data_a,
            integer list_id);

            linked_list_c new_element;
        begin
            this.position_list(
                address_a,
                linked_list[list_id]);

            // Insert at list tail
            if (found == null)
            begin
                prev.successor = new(address_a, data_a);
            end
            else
            begin
                // Element exists, update memory data value
                if (found.key_address == address_a)
                begin
                    found.val_data = data_a;
                end
                else
                begin
                    // No element found, allocate and link
                    new_element = new(address_a, data_a);
                    new_element.successor = found;
                    // Possible root position
                    if (prev != null)
                    begin
                        prev.successor = new_element;
                    end
                    else
                    begin
                        linked_list[list_id] = new_element;
                    end
                end
            end
        end
        endtask

        // Remove element from a linked list
        task remove_list(
            integer address_a,
            integer list_id);

        begin
            this.position_list(
                address_a,
                linked_list[list_id]);

            if (found != null)
                // Key value match
                if (found.key_address == address_a)
                begin
                    // Handle root position removal
                    if (prev != null)
                        prev.successor = found.successor;
                    else
                        linked_list[list_id] = found.successor;
                    // garbage collector
                    found = null;
                end
        end
        endtask

        // Remove range of elements from a linked list
        // Higher performance than one-by-one removal
        task remove_list_range(
            integer address_low,
            integer address_high,
            integer list_id);

            linked_list_c iter;
            linked_list_c prev_remove;
            linked_list_c link_element;
        begin
            iter = linked_list[list_id];
            prev_remove = null;
            // Find first linked list element belonging to
            // a specified address range [address_low, address_high]
            while ((iter != null) && !(
            (iter.key_address >= address_low) &&
            (iter.key_address <= address_high)))
            begin
                prev_remove = iter;
                iter = iter.successor;
            end
            // Continue until address_high reached
            // Deallocate linked list elements pointed by iterator
            if (iter != null)
            begin
                while ((iter != null) &&
                (iter.key_address >= address_low) &&
                (iter.key_address <= address_high))
                begin
                    link_element = iter.successor;
                    //garbage collector
                    iter.successor = null;
                    iter = link_element;
                end
                // Handle possible root value change
                if ( prev_remove != null )
                    prev_remove.successor = link_element;
                else
                    linked_list[list_id] = link_element;
            end
        end
        endtask

        // Create side linked list modelling corrupted memory area
        task create_list_range(
            integer address_low,
            integer address_high);

            linked_list_c new_element;
            linked_list_c prev_create;
            integer create_list_range_iter;
        begin
            sub_linked_list = new(address_low, -1);
            prev_create = sub_linked_list;
            // Linked list representing memory region :
            // [address_low, address_high], memory data value corrupted
            // Heightens corrupt and erase operation performance
            for(
            create_list_range_iter = (address_low + 1);
            create_list_range_iter <= address_high;
            create_list_range_iter = create_list_range_iter + 1)
            begin
                new_element = new(create_list_range_iter, -1);
                prev_create.successor = new_element;
                prev_create = new_element;
            end
            prev_create.successor = null;
            sub_linked_list_last = prev_create;
        end
        endtask

        // Merge corrupted with memory area
        task insert_list_range(
            integer list_id);

            integer key;
        begin
            if (linked_list[list_id] != null)
            begin
                key = sub_linked_list.key_address;
                // Insert side created corrupted memory region
                // into corresponding linked list
                this.position_list(key, linked_list[list_id]);
                if (found == null)
                    prev.successor = sub_linked_list;
                else
                begin
                    sub_linked_list_last.successor = found;
                    if (prev != null)
                        prev.successor = sub_linked_list;
                    else
                        linked_list[list_id] = sub_linked_list;
                end
            end
            else
                linked_list[list_id] = sub_linked_list;
            // do not prevent garabge collection when possible
            sub_linked_list = null;
            sub_linked_list_last = null;
        end
        endtask

    endclass

    // higher-level routines
    // provided memory RW operation class interface
    class rw_interface_c;

        low_level_interface_c low_level_interface;

        // assure proper initialization
        function new;
            integer new_iter;
        begin
            // allocate low level interface object
            low_level_interface = new;
        end
        endfunction

        task read_mem(
            inout integer data_a,
            input integer address_a);

            integer mem_data;
            integer list_id;
        begin
            // Higher performance, segment paritioning
            list_id = address_a / list_size;
            if (linked_list[list_id] == null)
                // Not allocated, not written, initial value
                mem_data = MaxData;
            else
            begin
                low_level_interface.position_list(
                    address_a,
                    linked_list[list_id]);
                if (found != null)
                begin
                    if (found.key_address == address_a)
                        // Allocated, val_data stored
                        mem_data = found.val_data;
                    else
                        // Not allocated, not written, initial value
                        mem_data = MaxData;
                end
                else
                begin
                    // Not allocated, not written, initial value
                    mem_data = MaxData;
                end
            end
            data_a = mem_data;
        end
        endtask

        // Memory WRITE operation performed above dynamically allocated space
        task write_mem(
            input integer address_a,
            input integer data_a);

            integer list_id;
        begin
            // Higher performance, segment paritioning
            list_id = address_a / list_size;
            if (data_a !== MaxData)
            begin
                // Handle possible root value update
                if (linked_list[list_id] !== null)
                begin
                    low_level_interface.insert_list(
                        address_a,
                        data_a,
                        list_id);
                end
                else
                begin
                    linked_list[list_id] =
                    new(address_a, data_a);
                end
            end
            else
            begin
                // Deallocate if initial value written
                // No linked list, NOP, initial value implicit
                if (linked_list[list_id] !== null)
                begin
                    low_level_interface.remove_list(
                        address_a,
                        list_id);
                end
            end
        end
        endtask

        // Address range to be corrupted
        task corrupt_mem(
            input integer address_low,
            input integer address_high);

            integer list_id;
        begin
            list_id = address_low / list_size;
            if (linked_list[list_id] != null)
                low_level_interface.remove_list_range(
                    address_low,
                    address_high,
                    list_id);
            low_level_interface.create_list_range(
                address_low,
                address_high
                );
            low_level_interface.insert_list_range(
                list_id
                );
        end
        endtask

        // Address range to be erased
        task erase_mem(
            input integer address_low,
            input integer address_high);

            integer list_id;
        begin
            list_id = address_low / list_size;
            low_level_interface.remove_list_range(
                address_low,
                address_high,
                list_id
                );
        end
        endtask

    endclass

    // object declaration holding memory management model
    rw_interface_c rw_interface;

    //interface towards higher hierarchy instances routine calls
    //wrapped from within the memory_features module
    //low-level routine access forbidden
    task initialize_w;
    begin
        rw_interface = new;
    end
    endtask

    task read_mem_w(
        inout integer data_a,
        input integer address_a);
    begin
        rw_interface.read_mem(data_a, address_a);
    end
    endtask

    task write_mem_w(
        input integer address_a,
        input integer data_a);
    begin
        rw_interface.write_mem(address_a, data_a);
    end
    endtask

    task erase_mem_w(
        input integer address_low,
        input integer address_high);
    begin
        rw_interface.erase_mem(address_low, address_high);
    end
    endtask

    task corrupt_mem_w(
        input integer address_low,
        input integer address_high);
    begin
        rw_interface.corrupt_mem(address_low, address_high);
    end
    endtask

    // -------------------------------------------------------------------------
    // ----------------    the end of memory management section    -------------
    // -------------------------------------------------------------------------
endmodule

