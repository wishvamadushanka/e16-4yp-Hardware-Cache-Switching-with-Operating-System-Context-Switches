
module memory_access_unit (
    input clock,reset,
    input mem_read_signal, mem_write_signal, mux5signal,
    input [31:0] mux4_out_result, data2,
    input [2:0] func3,
    output data_memory_busywait,
    output [31:0] mux5_out_write_data
);
    //parameters
    parameter  c_block_size = 2, c_line_size = 32, address_size = 32, c_assiotivity = 2, c_index = 1, mem_line_size = 32;

    wire [31:0] load_data, store_data, from_data_cache_out;

    // [c_line_size - 1:0] store_data;

    //cache to mem connectors
    wire c_m_busywait_i, c_m_read_o, c_m_wr_o, m_write_done, m_read_done;
    wire [2**c_block_size*c_line_size - 1 : 0] c_m_read_data_i;
    wire [2**c_block_size*c_line_size - 1 : 0] c_m_write_data_o;
    wire [address_size - c_block_size - 3:0] c_m_address_o;


    Data_store_controller dsc(func3,store_data,data2);
    Data_load_controller dlc(func3,from_data_cache_out,load_data);

    dcache #( .c_line_size(c_line_size), .c_assiotivity(c_assiotivity), .c_index(c_index), .c_block_size(c_block_size), .address_size(address_size) ) 
    dcache(data_memory_busywait, from_data_cache_out, c_m_write_data_o, c_m_read_o, c_m_wr_o, c_m_address_o, reset, clock, mux4_out_result, mem_read_signal, mem_write_signal, store_data, c_m_busywait_i, c_m_read_data_i, m_write_done, m_read_done);
    
    dmemory #(.c_block_size(c_block_size), .c_line_size(c_line_size), .address_size(address_size), .mem_line_size(mem_line_size) ) 
    data_memory(c_m_busywait_i, c_m_read_data_i, m_write_done, m_read_done, clock, reset, c_m_read_o, c_m_wr_o, c_m_address_o, c_m_write_data_o);
    

    // dcache mydcache(clock,reset,mem_read_signal,mem_write_signal,mux4_out_result,store_data,from_data_cache_out,data_memory_busywait);

    mux2x1 mux5(load_data,mux4_out_result,mux5signal,mux5_out_write_data);

endmodule