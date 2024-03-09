
module instruction_fetch_unit (
    input [31:0] branch_jump_addres,
    input branch_or_jump_signal,
    input data_memory_busywait,
    input reset,
    input clock,
    output reg [31:0] PC,INCREMENTED_PC_by_four,
    output [31:0]instruction,
    output busywait
);
wire [31:0]mux6out;
wire instruction_mem_busywait;

parameter  c_block_size = 2, c_line_size = 32, address_size = 32, c_assiotivity = 0, c_index = 8, mem_line_size = 32;
wire c_m_busywait_i, c_m_read_o, c_m_wr_o, m_write_done, m_read_done;
wire [2**c_block_size*c_line_size - 1 : 0] c_m_read_data_i;
wire [2**c_block_size*c_line_size - 1 : 0] c_m_write_data_o;
wire [address_size - c_block_size - 3:0] c_m_address_o;

reg mem_read_signal;


or(busywait,instruction_mem_busywait,data_memory_busywait);
mux2x1 mux6(INCREMENTED_PC_by_four,branch_jump_addres,branch_or_jump_signal,mux6out);
icache #( .c_line_size(c_line_size), .c_assiotivity(c_assiotivity), .c_index(c_index), .c_block_size(c_block_size), .address_size(address_size) ) 
 i_cache(instruction_mem_busywait, instruction, c_m_read_o, c_m_address_o, reset, clock, PC, mem_read_signal, c_m_busywait_i, c_m_read_data_i, m_read_done);
    
imemory #(.c_block_size(c_block_size), .c_line_size(c_line_size), .address_size(address_size), .mem_line_size(mem_line_size) ) 
 i_memory(c_m_busywait_i, c_m_read_data_i, m_read_done, clock, reset, c_m_read_o, c_m_address_o);

/*
always @(posedge reset) begin //set the pc value depend on the RESET to start the programme
    PC= -4;
end
*/

always @(*) begin
    INCREMENTED_PC_by_four <=PC+4;
end

always @(posedge clock,posedge reset) begin //update the pc value depend on the positive clock edge
	 if(reset)begin
		PC <= -4;
        mem_read_signal = 1'b0;
	 end
    else if(busywait == 1'b0)begin //update the pc when only busywait is zero 
        PC <= mux6out;
        mem_read_signal = 1'b1;
    end
end  
    
endmodule