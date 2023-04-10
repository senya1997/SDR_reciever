module AD9203_tb;

bit clk;
bit rst_n;

initial begin

end

AD9203 #(.CH_NUM(),     // num of used ADC
	     .D_BIT(),    // ADC data width 
         .DATA_DELAY()      // tact in ADC clk
) AD9203_i (
	.iCLK(),
	.iRST_N(),

	.iEN(),
	.iDFS(),

// ADC inteface:
	.iOTR(), // out of range indicate
	.iDATA(),

	.oCLK(),
	.oDFS(), // data format: 1 - twos complementary; 0 - straight binary
	.oTRI_ST(), // 1 - HiZ; 0 - active out
	.oSTBY(), // 1 - power down mode; 0 - normal

// in FPGA:
	.oDATA(),
	.oVALID(),
	.oOTR() // out of range
);

endmodule 
