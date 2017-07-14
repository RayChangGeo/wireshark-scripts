local HName = {}
HName[0] = "H0-Config"
HName[1] = "H1-DataBlock"
HName[2] = "H2-StateChange"
HName[3] = "H3-Position"
HName[4] = "H4-Tunnel"
HName[5] = "H5-MAC"
HName[6] = "H6-Battery"
HName[9] = "H9-KeepAlive"
HName[10] = "Unknown Header"

local stateName = {}
stateName[0] = "H2 ExitState == SAME"
stateName[1] = "H2 ExitState == OFF"
stateName[2] = "H2 ExitState == ON"
stateName[3] = "H2 ExitState == CAL"
stateName[4] = "H2 ExitState == SCAN (Start)"
stateName[5] = "H2 ExitState == IDLE (Stop)"
stateName[7] = "H2 ExitState == SW CAL"
stateName[8] = "H2 ExitState == UNKNOWN"

local paramName = {}
paramName[0] = "P0(Power Control)"
paramName[1] = "P1(Radar Global)"
paramName[2] = "P2(Radar Channel)"
paramName[3] = "P3(TX Protocol)"
paramName[4] = "P4(Single Param Update)"
paramName[5] = "P5(Position Control)"
paramName[6] = "P6(Direct Access)"
paramName[7] = "P7(huh?)"
paramName[8] = "P8(Special Operation)"
paramName[9] = "P9(Special Op Control Flags)"

local h_len
local h_offset

-- create GSSI protocol and its fields
local p_GSSIproto = Proto ("gssi","GSSI Protocol   ")

--local f = p_GSSIproto.fields
local f_port        = ProtoField.uint16("gssi.port", "UDP/TCP port", base.DEC)
local f_total_len   = ProtoField.int16("gssi.total_len", "Total Length", base.DEC)
local f_header_len  = ProtoField.int16("gssi.header_len", "Header Length", base.DEC)
local f_header_mask = ProtoField.uint16("gssi.header_mask", "Header Mask", base.HEX)
local f_sequence    = ProtoField.int32("gssi.sequence", "Sequence", base.DEC)
local f_timestamp   = ProtoField.uint32("gssi.timestamp", "Timestamp", base.DEC)

local f_H0_state      = ProtoField.uint16("gssi.h0_state", "  H0 Exit State", base.DEC)
local f_H0_par_type   = ProtoField.uint16("gssi.h0_par_type", "  -- Parameter Type", base.HEX)
local f_H0_cfg_offset = ProtoField.uint16("gssi.h0_cfg_offset", "  -- Config Data Offset", base.DEC)

local f_P1_nchannels  = ProtoField.int16("gssi.p1_nchannels", "  P1 Number of Channels", base.DEC)
local f_P1_nsamples   = ProtoField.int32("gssi.p1_samples", "  -- Samples per Channel", base.DEC)
local f_P1_nrepeats   = ProtoField.int16("gssi.p1_repeats", "  -- Number of Cycles averaged", base.DEC)
local f_P1_leadin     = ProtoField.int16("gssi.p1_leadin", "  -- Number of Pretrigger Cycles", base.DEC)
local f_P1_txrate     = ProtoField.int32("gssi.p1_txrate", "  -- TX period in pS", base.DEC)
local f_P1_scanrate   = ProtoField.int32("gssi.p1_scanrate", "  -- Scan Rate in milli-Hz", base.DEC)
local f_P1_radarmode  = ProtoField.uint32("gssi.p1_radarmode", "  -- Control/Mode Bits", base.HEX)
local f_P1_caliperiod = ProtoField.int32("gssi.p1_caliperiod", "  -- Cali Period in pS", base.DEC)
local f_P1_calibrate  = ProtoField.int16("gssi.p1_calibrate", "  -- Calibration Rate in scans", base.DEC)
local f_P1_system_id  = ProtoField.uint16("gssi.p1_leadin", "  -- Model SIR", base.HEX)

local f_P2_channum    = ProtoField.int16("gssi.p2_channum", "  P2 Channel Number", base.DEC)
local f_P2_rposition  = ProtoField.int32("gssi.p2_rposition", "  -- Receiver Position in pS", base.DEC)
local f_P2_tposition  = ProtoField.int32("gssi.p2_tposition", "  -- Transmitter Position in pS", base.DEC)
local f_P2_range      = ProtoField.int32("gssi.range", "  -- Time Range in pS", base.DEC)
local f_P2_timconfig  = ProtoField.uint32("gssi.timconfig", "  -- MUX Code RC/TR", base.HEX)
local f_P2_ratescale  = ProtoField.int32("gssi.ratescale", "  -- Rate Scale", base.DEC)

local f_P4_data_type  = ProtoField.int16("gssi.p4_data_type", "  P4 Update Type", base.DEC)
local f_P4_flags      = ProtoField.uint32("gssi.p4_flags", "  P4 Flags", base.HEX)
local f_P4_par1       = ProtoField.int32("gssi.p4_par1", "  P4 Par1", base.DEC)
local f_P4_par2       = ProtoField.int32("gssi.p4_par1", "  P4 Par2", base.DEC)

local f_P5_postype    = ProtoField.int16("gssi.p5_postype", "  P5 Position Type", base.DEC)
local f_P5_ticks_per_scan0 = ProtoField.int32("gssi.p5_ticks_per_scan0", "  -- Ticks per Scan[0]", base.DEC)
local f_P5_ticks_per_scan1 = ProtoField.int32("gssi.p5_ticks_per_scan1", "  -- Ticks per Scan[1]", base.DEC)
local f_P5_scans_per_mark = ProtoField.int32("gssi.p5_scans_per_mark", "  -- Scans per Mark", base.DEC)

local f_P8_nchannels  = ProtoField.int16("gssi.p8_nchannels", "  P8 Number of Channels", base.DEC)
local f_P8_nsamples   = ProtoField.int32("gssi.p8_nsamples", "  -- Number of Samples", base.DEC)
local f_P8_nrepeats   = ProtoField.int16("gssi.p8_nrepeats", "  -- Number of Repeats", base.DEC)
local f_P8_leadin     = ProtoField.int16("gssi.p8_leadin", "  -- Number of Pretrigger Cycles", base.DEC)
local f_P8_tx_rate    = ProtoField.int32("gssi.p8_tx_rate", "  -- Transmit Cycle Period in pS ", base.DEC)
local f_P8_scan_rate  = ProtoField.int32("gssi.p8_scan_rate", "  -- Scan Rate Count in milli-Hz ", base.DEC)
local f_P8_sys_setup  = ProtoField.uint32("gssi.p8_sys_setup", "  -- Special Temp System Config Flags ", base.HEX)
local f_P8_opvalue    = ProtoField.uint32("gssi.p8_opvalue", "  -- Operation Dependent Value ", base.HEX)
local f_P8_configs    = ProtoField.uint16("gssi.p8_configs", "  -- Extra Special Operation Config Flags ", base.HEX)
local f_P8_servo0_rx  = ProtoField.int32("gssi.p8_servo0_rx",       "  -- Servo0 Rx Position in pS ", base.DEC)
local f_P8_servo0_tx  = ProtoField.int32("gssi.p8_servo0_tx",       "  --        Tx Position in pS ", base.DEC)
local f_P8_servo0_range  = ProtoField.int32("gssi.p8_servo0_range", "  --        Range in pS ", base.DEC)
local f_P8_servo0_flags  = ProtoField.uint32("gssi.p8_servo0_flags","  --        Special Operation Flags ", base.HEX)
local f_P8_servo1_rx  = ProtoField.int32("gssi.p8_servo1_rx",       "  -- Servo1 Rx Position in pS ", base.DEC)
local f_P8_servo1_tx  = ProtoField.int32("gssi.p8_servo1_tx",       "  --        Tx Position in pS ", base.DEC)
local f_P8_servo1_range  = ProtoField.int32("gssi.p8_servo1_range", "  --        Range in pS ", base.DEC)
local f_P8_servo1_flags  = ProtoField.uint32("gssi.p8_servo1_flags","  --        Special Operation Flags ", base.HEX)

local f_H1_frames     = ProtoField.int8("gssi.frames", "  H1 Total frames", base.DEC)
local f_H1_frame_num  = ProtoField.int8("gssi.frame_num", "  -- Current Frame Number", base.DEC)
local f_H1_event_flags= ProtoField.uint8("gssi.flags", "  -- Event Flags", base.HEX)
local f_H1_scan_num   = ProtoField.int8("gssi.scan_num", "  -- Scan number", base.DEC)
local f_H1_dataoffset = ProtoField.uint32("gssi.data_offset", "  -- Data Offset", base.HEX)
local f_H1_chan_num   = ProtoField.int8("gssi.channum", "  -- Channel Number", base.DEC)

local f_H2_state                = ProtoField.uint16("gssi.h2_state", "  H2 State", base.DEC)
local f_H2_bin_number           = ProtoField.int32("gssi.h2_bin_number", "  -- Bin Number", base.DEC)
local f_H2_event_flags          = ProtoField.uint32("gssi.h2_event_flags", "  -- Event Flags", base.HEX)
local f_H2_critical_event_flags = ProtoField.uint32("gssi.h2_critical_event_flags", "  -- Critical Event Flags", base.HEX)

local f_H3_pos_type    = ProtoField.uint16("gssi.h3_pos_type", "  H3 Position Type", base.DEC)
local f_H3_bin_number  = ProtoField.int32("gssi.h3_bin_number", "  -- Bin Number", base.DEC)
local f_H3_quad_ticks1 = ProtoField.int32("gssi.h3_quad_ticks1", "  -- Quad Ticks1", base.DEC)
local f_H3_quad_ticks2 = ProtoField.int32("gssi.h3_quad_ticks2", "  -- Quad Ticks2", base.DEC)
local f_H3_accx        = ProtoField.int16("gssi.h3_accx", "  -- x Acceleration", base.DEC)
local f_H3_accy        = ProtoField.int16("gssi.h3_accy", "  -- y Acceleration", base.DEC)
local f_H3_accz        = ProtoField.int16("gssi.h3_accz", "  -- z Acceleration", base.DEC)
local f_H3_z_ang       = ProtoField.int16("gssi.h3_z_ang", "  -- Angle about z", base.DEC)

local f_H4_data_type        = ProtoField.uint16("gssi.h4_data_type", "  H4 Tunnel Data Type", base.DEC)
local f_H4_data_size        = ProtoField.int16("gssi.h4_data_size", "  -- Tunnel Data Size", base.DEC)
local f_H4_data_offset      = ProtoField.int16("gssi.h4_data_offset", "  -- Tunnel Data Offset", base.DEC)
local f_H4_data_compen      = ProtoField.int32("gssi.h4_data_compen", "  -- Tunnel Data compen", base.DEC)
local f_H4_data_block_number= ProtoField.int32("gssi.h4_data_block_number", "  -- Tunnel Data Block Number", base.DEC)

local f_H5_mac_address = ProtoField.ether("gssi.h5_mac_address", "  H5 MAC address", base.HEX)

local f_H6_battery_status = ProtoField.uint16("gssi.h6_battery_status", "  H6 Battery Status", base.DEC)
local f_H6_battery_voltage = ProtoField.uint16("gssi.h6_battery_voltage", "  -- Battery Voltage", base.DEC)
local f_H6_battery_charge = ProtoField.uint16("gssi.h6_battery_charge", "  -- Battery Charge", base.DEC)
local f_H6_battery2_voltage = ProtoField.uint16("gssi.h6_battery2_voltage", "  -- Battery 2 Voltage", base.DEC)
local f_H6_battery2_charge = ProtoField.uint16("gssi.h6_battery2_charge", "  -- Battery 2 Charge", base.DEC)
local f_H6_system_id = ProtoField.uint16("gssi.h6_system_id", "  -- System ID", base.HEX)
local f_H6_temperature = ProtoField.uint16("gssi.h6_temperature", "  -- temperature", base.DEC)

p_GSSIproto.fields = {f_port, f_total_len, f_header_len, f_header_mask, f_sequence, f_timestamp,
f_H0_state, f_H0_par_type, f_H0_cfg_offset,
f_P1_nchannels, f_P1_nsamples, f_P1_nrepeats, f_P1_leadin, f_P1_txrate, f_P1_scanrate, f_P1_radarmode, f_P1_caliperiod, f_P1_calibrate, f_P1_system_id,
f_P2_channum, f_P2_rposition, f_P2_tposition, f_P2_range, f_P2_timconfig, f_P2_ratescale,
f_P4_data_type, f_P4_flags, f_P4_par1, f_P4_par2,
f_P5_postype, f_P5_ticks_per_scan0, f_P5_ticks_per_scan1, f_P5_scans_per_mark,
f_P8_nchannels, f_P8_nsamples, f_P8_nrepeats, f_P8_leadin, f_P8_tx_rate, f_P8_scan_rate, f_P8_sys_setup, f_P8_opvalue, f_P8_configs, 
f_P8_servo0_rx,  f_P8_servo0_tx,  f_P8_servo0_range, f_P8_servo0_flags, f_P8_servo1_rx, f_P8_servo1_tx, f_P8_servo1_range, f_P8_servo1_flags,
f_H1_frames, f_H1_frame_num, f_H1_event_flags, f_H1_scan_num, f_H1_dataoffset, f_H1_chan_num, 
f_H2_state, f_H2_bin_number, f_H2_event_flags, f_H2_critical_event_flags,
f_H3_pos_type, f_H3_bin_number, f_H3_quad_ticks1, f_H3_quad_ticks2, f_H3_accx, f_H3_accy, f_H3_accz, f_H3_z_ang,
f_H4_data_type, f_H4_data_size, f_H4_data_offset, f_H4_data_compen, f_H4_data_block_number, 
f_H5_mac_address,
f_H6_battery_status, f_H6_battery_voltage, f_H6_battery_charge, f_H6_battery2_voltage, f_H6_battery2_charge, f_H6_system_id, f_H6_temperature}

function testbit(x,n)
   local p = 2^n
   return x%(p+p) >= p
end

-- GSSIproto dissector
function p_GSSIproto.dissector (buf, pkt, root)
   -- validate packet length is adequate, otherwise quit
   if buf:len() == 0 then return end

   pkt.cols.protocol = p_GSSIproto.name

   -- create subtree for GSSIproto
   subtree = root:add(p_GSSIproto, buf(0))
   -- add protocol fields to subtree
   subtree:add_le(f_port, buf(0,2)):append_text(" [Destination port (decimal)]")
   subtree:add_le(f_total_len, buf(2,2)):append_text(" [Total length not including this field]")
   subtree:add_le(f_header_len, buf(4,2)):append_text(" [Length including this field]")
   h_len = buf(4,1):uint()
   h_offset = 4

   local header_mask = buf(8,1):uint()
   local H_message = ""
   local P_message = ""
   local set_of_headers = {}
   local set_of_params = {}

   if header_mask == 0 then
      H_message = "NULL -- Heartbeat"
   else
      for i=0,9
	 do
	    if (testbit(header_mask,i)) then
	       table.insert(set_of_headers, i)
	       if H_message=="" then 
		  H_message = H_message..HName[i]
	       else
		  H_message = H_message.." + "..HName[i]
	       end
	    end
	 end        
      end
      subtree:add_le(f_header_mask, buf(8,2)):append_text(" ["..H_message.."]")

      subtree:add_le(f_sequence, buf(12,4))
      subtree:add_le(f_timestamp, buf(16,4)):append_text(" [In milliseconds]")
      h_offset = h_offset+h_len

      for h=1, #set_of_headers do
	 local header = set_of_headers[h]
	 h_len = buf(h_offset, 1):uint()

	 if header==0 then
	    local state = buf(h_offset+2, 1):uint()
	    subtree:add_le(f_H0_state, buf(h_offset+2, 2)):append_text(" ["..stateName[state].."]")
	    local p_types = buf(h_offset+4, 2):le_uint()
	    print("++++++++++ p_type = "..p_types)

	    for p=0,9
	       do
		  if (testbit(p_types, p)) then
		     print("p = "..p.." bit set")

		     table.insert(set_of_params, p)
		     if P_message=="" then

			P_message = paramName[p]
		     else
			P_message = P_message.." + "..paramName[p]
		     end		  
		  end
	       end
	       subtree:add_le(f_H0_par_type, buf(h_offset+4, 2)):append_text(" ["..P_message.."]")
	       subtree:add_le(f_H0_cfg_offset, buf(h_offset+6, 2))

	       -- advance to params
	       h_offset = h_offset+h_len;
	       h_len = 0;

	       --Paramters
	       for pm=1, #set_of_params do
		  local parm = set_of_params[pm]
		  local p_len = buf(h_offset, 2):le_uint()
		  if parm==1 then 
		     subtree:add_le(f_P1_nchannels, buf(h_offset+2, 2))
		     subtree:add_le(f_P1_nsamples,  buf(h_offset+4, 4))
		     subtree:add_le(f_P1_nrepeats,  buf(h_offset+8, 2))
		     subtree:add_le(f_P1_leadin,    buf(h_offset+10, 2))
		     subtree:add_le(f_P1_txrate, buf(h_offset+12, 4))
		     subtree:add_le(f_P1_scanrate, buf(h_offset+16, 4))
		     subtree:add_le(f_P1_radarmode, buf(h_offset+20, 4))
		     subtree:add_le(f_P1_caliperiod, buf(h_offset+24, 4))
		     subtree:add_le(f_P1_calibrate, buf(h_offset+28, 2))
		     subtree:add_le(f_P1_system_id, buf(h_offset+30, 2))	   
		  elseif parm==2 then
		     subtree:add_le(f_P2_channum, buf(h_offset+2, 2))
		     subtree:add_le(f_P2_rposition, buf(h_offset+4, 4))
		     subtree:add_le(f_P2_tposition, buf(h_offset+8, 4))
		     subtree:add_le(f_P2_range, buf(h_offset+12, 4))
		     subtree:add_le(f_P2_timconfig, buf(h_offset+16, 4))
		     subtree:add_le(f_P2_ratescale, buf(h_offset+20, 4))
		  elseif parm==3 then
		  elseif parm==4 then
                     subtree:add_le(f_P4_data_type, buf(h_offset+2, 2))
		     subtree:add_le(f_P4_flags, buf(h_offset+4, 4))
		     subtree:add_le(f_P4_par1, buf(h_offset+8, 4))
		     subtree:add_le(f_P4_par2, buf(h_offset+12, 4))
		  elseif parm==5 then
		     subtree:add_le(f_P5_postype, buf(h_offset+2, 2))
		     subtree:add_le(f_P5_ticks_per_scan0, buf(h_offset+4, 4))
		     subtree:add_le(f_P5_ticks_per_scan1, buf(h_offset+8, 4))
		     subtree:add_le(f_P5_scans_per_mark, buf(h_offset+12, 4))
		  elseif parm==6 then
		  elseif parm==7 then
		  elseif parm==8 then
		     subtree:add_le(f_P8_nchannels, buf(h_offset+2, 2))
		     subtree:add_le(f_P8_nsamples, buf(h_offset+4, 4))
                     subtree:add_le(f_P8_nrepeats, buf(h_offset+8, 2))
                     subtree:add_le(f_P8_leadin, buf(h_offset+10, 2))
                     subtree:add_le(f_P8_tx_rate, buf(h_offset+12, 4))
                     subtree:add_le(f_P8_scan_rate, buf(h_offset+16, 4))
                     subtree:add_le(f_P8_sys_setup, buf(h_offset+20, 4))
                     subtree:add_le(f_P8_opvalue, buf(h_offset+24, 4))
                     subtree:add_le(f_P8_configs, buf(h_offset+28, 2))
                     subtree:add_le(f_P8_servo0_rx, buf(h_offset+32, 4))
                     subtree:add_le(f_P8_servo0_tx, buf(h_offset+36, 4))
                     subtree:add_le(f_P8_servo0_range, buf(h_offset+40, 4))
                     subtree:add_le(f_P8_servo0_flags, buf(h_offset+44, 4))
                     subtree:add_le(f_P8_servo1_rx, buf(h_offset+48, 4))
                     subtree:add_le(f_P8_servo1_tx, buf(h_offset+52, 4))
                     subtree:add_le(f_P8_servo1_range, buf(h_offset+56, 4))
                     subtree:add_le(f_P8_servo1_flags, buf(h_offset+60, 4))
		  elseif parm==9 then
		  end

		  h_offset = h_offset+p_len
	       end


	    elseif header==1 then
	       -- decode H1
	       subtree:add_le(f_H1_frames, buf(h_offset+2,1))
	       subtree:add_le(f_H1_frame_num, buf(h_offset+3,1))
	       subtree:add_le(f_H1_event_flags, buf(h_offset+4, 4))
	       subtree:add_le(f_H1_scan_num, buf(h_offset+8, 4))
	       subtree:add_le(f_H1_dataoffset, buf(h_offset+12, 2))
	       subtree:add_le(f_H1_chan_num, buf(h_offset+14,1))

	    elseif header==2 then
	       -- decode H2
	       local exit_state = buf(h_offset+2, 1):uint()
	       if exit_state > #stateName then
		  exit_state = #stateName
	       end
	       subtree:add_le(f_H2_state, buf(h_offset+2, 2)):append_text(" ["..stateName[exit_state].."]")
	       subtree:add_le(f_H2_bin_number, buf(h_offset+4, 4))
	       subtree:add_le(f_H2_event_flags, buf(h_offset+8, 4))
	       subtree:add_le(f_H2_critical_event_flags, buf(h_offset+12, 4))

	    elseif header==3 then
	       -- decode H3
	       local p_type = buf(h_offset+2, 2):uint()
	       subtree:add_le(f_H3_pos_type, buf(h_offset+2, 2))
	       subtree:add_le(f_H3_bin_number, buf(h_offset+4, 4))
	       if p_type==0x0110 then
		  subtree:add_le(f_H3_quad_ticks1, buf(h_offset+8, 4))
		  subtree:add_le(f_H3_quad_ticks2, buf(h_offset+12, 4))
	       else
		  subtree:add_le(f_H3_accx, buf(h_offset+8, 2))
		  subtree:add_le(f_H3_accy, buf(h_offset+10, 2))
		  subtree:add_le(f_H3_accz, buf(h_offset+12, 2))
		  subtree:add_le(f_H3_z_ang, buf(h_offset+14, 2))
	       end

	    elseif header==4 then
	       -- decode H4
	       subtree:add_le(f_H4_data_type, buf(h_offset+2, 2)):append_text(" [ARM[8], FPGA(9), SD(10) ]")
	       subtree:add_le(f_H4_data_size, buf(h_offset+4, 2))
	       subtree:add_le(f_H4_data_offset, buf(h_offset+6, 2))
	       subtree:add_le(f_H4_data_compen, buf(h_offset+8, 4))
	       subtree:add_le(f_H4_data_block_number, buf(h_offset+12, 4))

	    elseif header==5 then
	       subtree:add(f_H5_mac_address, buf(h_offset+2, 6))

	    elseif header==6 then
	       subtree:add_le(f_H6_battery_status, buf(h_offset+2, 2))
	       subtree:add_le(f_H6_battery_voltage, buf(h_offset+4, 2)):append_text("mv")
	       subtree:add_le(f_H6_battery_charge, buf(h_offset+6, 2)):append_text("%")
	       subtree:add_le(f_H6_battery2_voltage, buf(h_offset+8, 2)):append_text("mv")
	       subtree:add_le(f_H6_battery2_charge, buf(h_offset+10, 2)):append_text("%")
	       subtree:add_le(f_H6_system_id, buf(h_offset+12, 2))
	       subtree:add_le(f_H6_temperature, buf(h_offset+14, 2))

	    elseif header==9 then
	    end
	    -- next logical
	    h_offset = h_offset+h_len

	 end 

	 -- description of payload
	 subtree:append_text("command(s)")
      end

      -- Initialization routine
      function p_GSSIproto.init()
      end

      -- register a chained dissector for port 1634
      local tcp_dissector_table = DissectorTable.get("tcp.port")
      dissector = tcp_dissector_table:get_dissector(1634)
      -- you can call dissector from function p_GSSIproto.dissector above
      -- so that the previous dissector gets called
      tcp_dissector_table:add(1634, p_GSSIproto)
