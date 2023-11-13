#!/usr/bin/python
##
## This file is part of the libsigrokdecode project.
##
## Copyright (C) 2018 fenugrec <fenugrec@users.sourceforge.net>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.
##

import sigrokdecode as srd

class ChannelError(Exception):
    pass

class Decoder(srd.Decoder):
    api_version = 3
    id = 'onfi'
    name = 'ONFI'
    longname = 'ONFI NAND Flash'
    desc = 'ONFI NAND Flash interface, used by MicroSD cards, Pendrives, TSOP48, BGA152, BGA362. https://www.onfi.org/specifications'
    license = 'gplv2+'
    inputs = ['logic']
    outputs = []
    tags = ['IC', 'Memory', 'IC/Memory', 'NAND Flash']
    options = (
        {'id': 'onfi', 'desc': 'ONFI Standard',
            'default': '3.2', 'values': ('1.0', '2.0', '2.1', '2.2', '2.3a', '3.0', '3.1', '3.2', '4.0', '4.1', '4.2', '5.0', '5.1')},
        {'id': 'wordsize', 'desc': 'IO pins',
            'default': 8, 'value': ('8', '16')},
        {'id': 'mode', 'desc': 'Data Rate mode',
            'default': 'SDR', 'values': ('SDR', 'NV-DDR', 'NV-DDR2', 'NV-DDR3', 'NV-LPDDR4')},
    )
  
    channels = (
        {'id': 'ale', 'name': 'ALE', 'desc': 'Address latch enable'},
        {'id': 'cle', 'name': 'CLE', 'desc': 'Address latch enable'},
        {'id': 'nce', 'name': 'nCE', 'desc': 'Chip Enable (inverted)'},
        {'id': 'nwe', 'name': 'nWE', 'desc': 'Write Enable (inverted)'},
        {'id': 'nwp', 'name': 'nWP', 'desc': 'Write Protect (inverted)'},
        {'id': 'nre', 'name': 'nRE', 'desc': 'Read Enabled (inverted)'},
        {'id': 'rnb', 'name': 'RNB', 'desc': 'Ready/Busy - Low: Busy'},
    ) + tuple({
        'id': 'io%d' % i,
        'name': 'IO%d' % i,
        'desc': 'CPU data line %d' % i
        } for i in range(0, 8)
    ) 
    optional_channels = (
        {'id': 'nwr', 'name': 'W/R_n', 'desc': 'Write/Read Direction'},
        {'id': 'clk', 'name': 'CLK', 'desc': 'Clock (only used for NV-DDR'},
    ) + tuple({ 
        'id': 'io%d' % i,
        'name': 'IO%d' % i,
        'desc': 'CPU address line %d' % i
        } for i in range(8, 16)
    ) + tuple({ 
        'id': 'ce%d' % i,
        'name': 'CE%d' % i,
        'desc': 'Chip Enable line %d' % i
        } for i in range(2, 8)
    )

    annotations = (
        ('data', 'Data'),
        ('addr', 'Address'),
        ('cmd', 'Command'),
        ('status', 'Status'),
        ('warnings', 'Warnings'),
    )
    binary = (
        ('data', 'AAAA:DD'),
    )
    OFF_ALE, OFF_PSEN = 0, 1
    OFF_DATA_BOT, OFF_DATA_TOP = 2, 10
    OFF_ADDR_BOT, OFF_ADDR_TOP = 10, 14
    OFF_BANK_BOT, OFF_BANK_TOP = 14, 15

    def __init__(self):
        self.reset()

    def reset(self):
        self.addr = 0
        self.addr_s = 0
        self.data = 0
        self.data_s = 0

        # Flag to make sure we get an ALE pulse first.
        self.started = 0

    def start(self):
        self.out_ann = self.register(srd.OUTPUT_ANN)
        #self.out_bin = self.register(srd.OUTPUT_BINARY)

    def newaddr(self, addr, data):
        # Falling edge on ALE: reconstruct address.
        self.started = 1
        addr = sum([bit << i for i, bit in enumerate(addr)])
        addr <<= len(data)
        addr |= sum([bit << i for i, bit in enumerate(data)])
        self.addr = addr
        self.addr_s = self.samplenum

    def newdata(self, data):
        # Edge on PSEN: get data.
        data = sum([bit << i for i, bit in enumerate(data)])
        self.data = data
        self.data_s = self.samplenum
        if self.started:
            anntext = '{:04X}:{:02X}'.format(self.addr, self.data)
            self.put(self.addr_s, self.data_s, self.out_ann, [0, [anntext]])
            bindata = self.addr.to_bytes(2, byteorder='big')
            bindata += self.data.to_bytes(1, byteorder='big')
            self.put(self.addr_s, self.data_s, self.out_bin, [0, bindata])


    def decode(self):
        # Address bits above A11 are optional, and are considered to be A12+.
        # This logic needs more adjustment when more bank address pins are
        # to get supported. For now, having just A12 is considered sufficient.
        self.put(self.OFF_DATA_BOT,self.OFF_DATA_TOP,self.out_ann,[4,['Error:Timing violated','Timing','X']])
        return
        has_bank = self.has_channel(self.OFF_BANK_BOT)
        bank_pin_count = 1 if has_bank else 0
        # Sample address on the falling ALE edge.
        # Save data on falling edge of PSEN.
        while True:
            pins = self.wait([{self.OFF_ALE: 'f'}, {self.OFF_PSEN: 'r'}])
            data = pins[self.OFF_DATA_BOT:self.OFF_DATA_TOP]
            addr = pins[self.OFF_ADDR_BOT:self.OFF_ADDR_TOP]
            bank = pins[self.OFF_BANK_BOT:self.OFF_BANK_TOP]
            if has_bank:
                addr += bank[:bank_pin_count]
            # Handle those conditions (one or more) that matched this time.
            if self.matched[0]:
                self.newaddr(addr, data)
            if self.matched[1]:
                self.newdata(data)
                
"""
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
    $setup ( posedge R      ,negedge RENeg,        tsetup_R_RENeg     , Viol);
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
"""          

