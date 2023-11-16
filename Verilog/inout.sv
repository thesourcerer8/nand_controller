

module module1(data);
  inout [3:0] data;
  reg [3:0] data_reg;
  assign data=data_reg;

  initial begin
	  data_reg=4'hZ;
	  #1;
	  data_reg=4'hA;
	  #5;
	  data_reg=4'hZ;
	  #10;
end
endmodule


module module2(data0,data1,data2,data3);
  inout data0;
  inout data1;
  inout data2;
  inout data3;
  reg data0_reg;
  reg data1_reg;
  reg data2_reg;
  reg data3_reg;
  assign data0=data0_reg;
  assign data1=data1_reg;
  assign data2=data2_reg;
  assign data3=data3_reg;

  initial begin
	  data0_reg=1'bZ;
	  data1_reg=1'bZ;
	  data2_reg=1'bZ;
	  data3_reg=1'bZ;
	  #7;
	  data0_reg=1'b1;
	  data1_reg=1'b1;
	  data2_reg=1'b0;
	  data3_reg=1'b1;
	  #5;
	  data0_reg=1'bZ;
	  data1_reg=1'bZ;
	  data2_reg=1'bZ;
	  data3_reg=1'bZ;
	  #7;
	  data0_reg=1'b1;
	  data1_reg=1'b1;
	  data2_reg=1'b0;
	  data3_reg=1'b1;
	  #10;
end
endmodule

module top();
wire [3:0] mydata;
	module1 m1(.data(mydata));
	module2 m2(.data0(mydata[0]), .data1(mydata[1]), .data2(mydata[2]), .data3(mydata[3]));

initial begin
        $dumpfile("inout.vcd");
        $dumpvars(0,top);
        $timeformat(-9, 0, "ns", 8);
	#20;
	$finish;
end
endmodule

