/*
AD9203
    max 40 MHz <=> 25 ns tact
    data delay 5.5 tact in ADC clk

latch ADC data on front:
    tsu(max)    = 25 - 7 = 18 ns
    th(max)     = 3 ns

latch ADC data on fall:
    tsu(max)    = 25/2 - 7 = 5.5 ns
    th(max)     = 25/2 + 3 = 15.5 ns
*/

module AD9203 #(parameter CH_NUM        = 2,     // num of used ADC
	                      D_BIT         = 10,    // ADC data width 
                          DATA_DELAY    = 8      // tact in ADC clk
)(
	input iCLK,
	input iRST_N,

	input iEN,

	input iDFS,

// ADC inteface:
	input [CH_NUM - 1 : 0] iOTR, // out of range indicate
	input [CH_NUM - 1 : 0][D_BIT - 1 : 0] iDATA,

	output [CH_NUM - 1 : 0] oCLK,
	output [CH_NUM - 1 : 0] oDFS, // data format: 1 - twos complementary; 0 - straight binary
	output [CH_NUM - 1 : 0] oTRI_ST, // 1 - HiZ; 0 - active out
	output [CH_NUM - 1 : 0] oSTBY, // 1 - power down mode; 0 - normal

// in FPGA:
	output [CH_NUM - 1 : 0][D_BIT - 1 : 0] oDATA,
	output oVALID,
	output [CH_NUM - 1 : 0] oOTR // out of range
);
	localparam START_DELAY = 3; // in tact of ADC clk

	logic en_conv;
	logic [START_DELAY - 1 : 0] en_conv_d;

	logic [$clog2(DATA_DELAY) - 1 : 0] cnt_delay_data;

// for ADC:
	logic adc_in_tri_st;
	logic adc_in_stby;
	logic data_format;

// for FPGA:
	logic [CH_NUM - 1 : 0][D_BIT - 1 : 0] data;
	logic [CH_NUM - 1 : 0] otr;
	logic valid;
	
wire ADC_DATA_RDY = (cnt_delay_data >= DATA_DELAY);

always@(posedge iCLK or negedge iRST_N) begin
	if(!iRST_N)
		en_conv <= 1'b0;
	else if(iEN)
		en_conv <= 1'b1;
	else
		en_conv <= 1'b0;
end

always@(posedge iCLK or negedge iRST_N) begin
	if(!iRST_N)
		cnt_delay_data <= '0;
	else if(en_conv)
	    begin
			if(cnt_delay_data < DATA_DELAY) 
				cnt_delay_data <= cnt_delay_data + 1;
		end
	else
		cnt_delay_data <= '0';
end

always@(posedge iCLK or negedge iRST_N) begin
	if(!iRST_N)
		begin
			data <= '0;
			otr <= '0;
		end
	if(ADC_DATA_RDY)
		begin
			data <= iDATA;
			otr <= iOTR;
		end
end

always@(posedge iCLK) begin
	en_conv_d      <= {en_conv_d[START_DELAY - 2 : 0], en_conv};

	adc_in_tri_st  <= (~en_conv_d(START_DELAY - 1)) || (~en_conv);
	adc_in_stby    <= (~en_conv_d(START_DELAY - 1)) && (~en_conv);

	valid          <= ADC_DATA_RDY;
	data_format    <= iDFS;
end

// output
	// ADC:
		assign oDFS      = {CH_NUM{data_format}};
		assign oCLK      = {CH_NUM{iCLK}};
		assign oTRI_ST   = {CH_NUM{adc_in_tri_st}};
		assign oSTBY     = {CH_NUM{adc_in_stby}};

	// FPGA:
		assign oDATA     = data;
		assign oOTR      = otr;
		assign oVALID    = valid;
endmodule 
